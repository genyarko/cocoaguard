import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../utils/constants.dart';
import '../utils/image_utils.dart';
import '../utils/interpreter_options_builder.dart';

class LeafClassificationResult {
  final String diagnosis;
  final double confidence;
  final List<double> allScores;
  final Map<String, double> scoreMap;
  /// True when CSSVD was flagged based on the 30% threshold override
  final bool isPotentiallyInfected;

  LeafClassificationResult({
    required this.diagnosis,
    required this.confidence,
    required this.allScores,
    required this.scoreMap,
    this.isPotentiallyInfected = false,
  });
}

class LeafClassifierService {
  Interpreter? _interpreter;
  List<String> _classNames = [];
  bool _isLoading = false;

  bool get isReady => _interpreter != null && _classNames.isNotEmpty;
  bool get isLoading => _isLoading;

  /// Load the model. Safe to call multiple times — returns immediately if
  /// already loaded or currently loading.
  Future<void> init() async {
    if (isReady || _isLoading) return;
    _isLoading = true;
    final sw = Stopwatch()..start();
    try {
      final options = InterpreterOptionsBuilder.build(label: 'leaf');
      _interpreter = await Interpreter.fromAsset(
          AppConstants.leafModelPath, options: options);

      final labelsJson =
          await rootBundle.loadString(AppConstants.leafLabelsPath);
      final labelsData = json.decode(labelsJson) as Map<String, dynamic>;
      _classNames = List<String>.from(labelsData['class_names']);
      debugPrint('[PERF] Leaf model loaded in ${sw.elapsedMilliseconds}ms');
    } finally {
      _isLoading = false;
    }
  }

  LeafClassificationResult classify(File imageFile) {
    if (!isReady) throw StateError('Leaf classifier not initialized. Call init() first.');

    final sw = Stopwatch()..start();
    final image = ImageUtils.preprocessFile(imageFile);
    final preprocessMs = sw.elapsedMilliseconds;

    final input = ImageUtils.imageToFloat32Tensor(image);

    // Reshape input to [1, 300, 300, 3]
    final inputTensor = input.reshape([1, 300, 300, 3]);

    // Output buffer [1, numClasses]
    final output = List.filled(1 * _classNames.length, 0.0).reshape([1, _classNames.length]);

    _interpreter!.run(inputTensor, output);
    debugPrint('[PERF] Leaf classify: preprocess=${preprocessMs}ms, '
        'total=${sw.elapsedMilliseconds}ms');

    final scores = List<double>.from(output[0]);

    // Find top prediction
    var maxIdx = 0;
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > scores[maxIdx]) maxIdx = i;
    }

    final scoreMap = <String, double>{};
    for (var i = 0; i < _classNames.length; i++) {
      scoreMap[_classNames[i]] = scores[i];
    }

    // If CSSVD score is >= 30%, flag as potentially infected even if not top class
    final cssvdIdx = _classNames.indexOf('cssvd');
    String diagnosis = _classNames[maxIdx];
    double confidence = scores[maxIdx];
    bool potentiallyInfected = false;
    if (cssvdIdx >= 0 &&
        scores[cssvdIdx] >= 0.30 &&
        _classNames[maxIdx] != 'cssvd') {
      diagnosis = 'cssvd';
      confidence = scores[cssvdIdx];
      potentiallyInfected = true;
    }

    return LeafClassificationResult(
      diagnosis: diagnosis,
      confidence: confidence,
      allScores: scores,
      scoreMap: scoreMap,
      isPotentiallyInfected: potentiallyInfected,
    );
  }

  /// Release the interpreter to free memory. The model will be reloaded on
  /// the next call to [init].
  void unload() {
    _interpreter?.close();
    _interpreter = null;
    _classNames = [];
  }

  void dispose() {
    unload();
  }
}
