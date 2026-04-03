import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/bounding_box.dart';
import '../models/detected_pod.dart';
import '../models/diagnosis_result.dart';
import '../utils/constants.dart';
import '../utils/image_cropper.dart';
import '../utils/interpreter_options_builder.dart';
import 'score_blender.dart';
import 'yolo_detector.dart';

class PodClassifierService extends ChangeNotifier {
  Interpreter? _interpreter;
  List<String> _classNames = [];
  Map<String, String> _displayNames = {};
  final YoloDetector _yoloDetector = YoloDetector();

  bool _isLoaded = false;
  bool _isLoading = false;

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;

  static const int _inputSize = 300;
  static const double _confidenceThreshold = 0.50;

  Future<void> loadModel() async {
    if (_isLoaded) return;
    _isLoading = true;
    notifyListeners();

    final sw = Stopwatch()..start();
    try {
      final options = InterpreterOptionsBuilder.build(label: 'pod');
      _interpreter = await Interpreter.fromAsset(
          AppConstants.podModelPath, options: options);

      final labelsJson =
          await rootBundle.loadString(AppConstants.podLabelsPath);
      final data = json.decode(labelsJson) as Map<String, dynamic>;
      _classNames = List<String>.from(data['class_names']);
      _displayNames = Map<String, String>.from(data['display_names']);

      await _yoloDetector.loadModel();

      _isLoaded = true;
      debugPrint('[PERF] Pod models loaded in ${sw.elapsedMilliseconds}ms');
    } catch (e, st) {
      debugPrint('Failed to load pod models: $e\n$st');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Runs YOLO detection then classifies each detected pod crop.
  Future<DetectionResult?> detectAndClassify(img.Image image,
      {Uint8List? originalBytes}) async {
    if (!_isLoaded) {
      await loadModel();
      if (!_isLoaded) return null;
    }

    try {
      // Use very lenient confidence threshold for pod detection
      // (default 0.20 was too strict - using 0.05 to catch more detections)
      var boxes = await _yoloDetector.detectWithThreshold(image, confidenceThreshold: 0.05);

      if (boxes.isEmpty) return null;

      // Cap at 10 pods to prevent OOM crashes on busy images.
      // Sort by confidence descending and keep the top detections.
      if (boxes.length > 10) {
        boxes = List.from(boxes)
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
        boxes = boxes.sublist(0, 10);
        debugPrint('Capped to 10 highest-confidence pods');
      }

      final pods = <DetectedPod>[];
      final podTimer = Stopwatch()..start();
      for (int i = 0; i < boxes.length; i++) {
        final crop = ImageCropper.crop(image, boxes[i]);
        final diagnosis = _classifyAndBlend(crop, boxes[i]);
        if (diagnosis != null) {
          // Encode crop as JPEG (much smaller than PNG) to reduce memory
          pods.add(DetectedPod(
            box: boxes[i],
            diagnosis: diagnosis,
            cropBytes: Uint8List.fromList(img.encodeJpg(crop, quality: 80)),
          ));
        }
      }
      debugPrint('[PERF] Classified ${pods.length} pods in '
          '${podTimer.elapsedMilliseconds}ms '
          '(${pods.isNotEmpty ? podTimer.elapsedMilliseconds ~/ pods.length : 0}ms/pod)');

      if (pods.isEmpty) return null;

      return DetectionResult(
        pods: pods,
        imageWidth: image.width,
        imageHeight: image.height,
        imageBytes: originalBytes,
        timestamp: DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('Detection pipeline error: $e\n$st');
      return null;
    }
  }

  /// Classifies a single pod crop and blends with YOLO's detection scores.
  DiagnosisResult? _classifyAndBlend(img.Image image, BoundingBox box) {
    if (_interpreter == null) return null;

    try {
      final input = _preprocess(image);
      final inputTensor =
          input.reshape([1, _inputSize, _inputSize, 3]);
      final output =
          List.filled(1 * _classNames.length, 0.0)
              .reshape([1, _classNames.length]);

      _interpreter!.run(inputTensor, output);

      final classifierScores = List<double>.from(output[0]);
      final classifierResult = _postprocess(classifierScores);

      final blended = ScoreBlender.blend(
        classifierResult.probabilities,
        box.classScores,
      );

      // Find top-1 and top-2 from blended probabilities
      int topIndex = 0;
      int secondIndex = -1;
      double topConf = blended[0];
      double secondConf = -1;
      for (int i = 1; i < blended.length; i++) {
        if (blended[i] > topConf) {
          secondConf = topConf;
          secondIndex = topIndex;
          topConf = blended[i];
          topIndex = i;
        } else if (blended[i] > secondConf) {
          secondConf = blended[i];
          secondIndex = i;
        }
      }

      // Build differential diagnosis when result is ambiguous
      AlternativeDiagnosis? alternative;

      final classifierIsDiseased = classifierResult.classIndex != ScoreBlender.healthyClassIndex;
      final classifierOverridden = classifierResult.classIndex != topIndex;
      if (classifierIsDiseased && classifierOverridden) {
        alternative = AlternativeDiagnosis(
          className: _classNames[classifierResult.classIndex],
          displayName: _displayName(classifierResult.classIndex),
          confidence: blended[classifierResult.classIndex],
        );
      }

      if (alternative == null && secondIndex >= 0) {
        final gap = topConf - secondConf;
        final classifierDisagrees = classifierResult.classIndex != box.classIndex;
        final secondIsDiseased = secondIndex != ScoreBlender.healthyClassIndex;
        if (gap < 0.20 ||
            (classifierDisagrees && secondIsDiseased && secondConf > 0.10)) {
          alternative = AlternativeDiagnosis(
            className: _classNames[secondIndex],
            displayName: _displayName(secondIndex),
            confidence: secondConf,
          );
        }
      }

      return DiagnosisResult(
        className: _classNames[topIndex],
        displayName: _displayName(topIndex),
        confidence: topConf,
        isUncertain: topConf < _confidenceThreshold,
        probabilities: blended,
        timestamp: DateTime.now(),
        alternative: alternative,
      );
    } catch (e) {
      debugPrint('Crop classification error: $e');
      return null;
    }
  }

  /// Preprocesses an image for EfficientNetB3: resize to 300×300, 0–255 range.
  Float32List _preprocess(img.Image image) {
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    final buffer = Float32List(1 * _inputSize * _inputSize * 3);
    int offset = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[offset++] = pixel.r.toDouble();
        buffer[offset++] = pixel.g.toDouble();
        buffer[offset++] = pixel.b.toDouble();
      }
    }
    return buffer;
  }

  /// Finds top class and computes softmax if needed.
  ({int classIndex, double confidence, List<double> probabilities})
      _postprocess(List<double> scores) {
    // Apply softmax if outputs look like logits (not bounded 0-1)
    final maxVal = scores.reduce(math.max);
    final List<double> probs;
    if (maxVal > 1.5) {
      final exps = scores.map((s) => math.exp(s - maxVal)).toList();
      final sumExps = exps.reduce((a, b) => a + b);
      probs = exps.map((e) => e / sumExps).toList();
    } else {
      probs = scores;
    }

    int topIndex = 0;
    double topConf = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > topConf) {
        topConf = probs[i];
        topIndex = i;
      }
    }

    return (
      classIndex: topIndex,
      confidence: topConf,
      probabilities: probs,
    );
  }

  String _displayName(int index) {
    if (index < 0 || index >= _classNames.length) return 'Unknown';
    final cn = _classNames[index];
    return _displayNames[cn] ?? cn;
  }

  /// Release interpreters to free memory. Models will be reloaded on next
  /// [detectAndClassify] call.
  void unload() {
    _interpreter?.close();
    _interpreter = null;
    _yoloDetector.dispose();
    _isLoaded = false;
    _classNames = [];
    _displayNames = {};
  }

  @override
  void dispose() {
    _interpreter?.close();
    _yoloDetector.dispose();
    super.dispose();
  }
}
