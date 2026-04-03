import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/bounding_box.dart';
import '../utils/constants.dart';
import 'yolo_preprocessor.dart';
import 'yolo_postprocessor.dart';

class YoloDetector {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  List<int> _inputShape = [];
  List<int> _outputShape = [];
  bool _inputIsNchw = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    if (_isLoaded) return;
    final sw = Stopwatch()..start();
    try {
      _interpreter = await Interpreter.fromAsset(AppConstants.yoloModelPath);

      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;
      _inputIsNchw =
          _inputShape.length == 4 && _inputShape[1] == 3 && _inputShape[2] > 3;
      debugPrint('YOLO input shape: $_inputShape (${_inputIsNchw ? "NCHW" : "NHWC"})');
      debugPrint('YOLO output shape: $_outputShape');

      _isLoaded = true;
      debugPrint('[PERF] YOLO model loaded in ${sw.elapsedMilliseconds}ms');
    } catch (e, st) {
      debugPrint('Failed to load YOLO model: $e\n$st');
    }
  }

  /// Runs YOLO detection on the image and returns bounding boxes
  /// in original image coordinates.
  Future<List<BoundingBox>> detect(img.Image image) async {
    return detectWithThreshold(image);
  }

  /// Runs YOLO detection with custom confidence threshold
  Future<List<BoundingBox>> detectWithThreshold(
    img.Image image, {
    double confidenceThreshold = 0.20,
    double iouThreshold = 0.45,
  }) async {
    if (!_isLoaded || _interpreter == null) return [];

    final sw = Stopwatch()..start();
    final (input, letterbox) =
        YoloPreprocessor.process(image, nchw: _inputIsNchw);
    final preprocessMs = sw.elapsedMilliseconds;
    final inputTensor = input.reshape(_inputShape);
    final output = _allocateOutput(_outputShape);

    _interpreter!.run(inputTensor, output);
    debugPrint('[PERF] YOLO detect: preprocess=${preprocessMs}ms, '
        'inference=${sw.elapsedMilliseconds - preprocessMs}ms, '
        'total=${sw.elapsedMilliseconds}ms');

    final int channels;
    final int numPreds;
    final List<double> flat;

    if (_outputShape.length == 3) {
      final dim1 = _outputShape[1];
      final dim2 = _outputShape[2];

      if (dim1 < dim2) {
        channels = dim1;
        numPreds = dim2;
        flat = _flattenChannelMajor(output, channels, numPreds);
      } else {
        channels = dim2;
        numPreds = dim1;
        flat = _transposeThenFlatten(output, numPreds, channels);
      }
    } else {
      debugPrint('Unexpected YOLO output rank: ${_outputShape.length}');
      return [];
    }

    return YoloPostprocessor.process(
      rawOutput: flat,
      letterbox: letterbox,
      channels: channels,
      numPreds: numPreds,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold,
    );
  }

  List<dynamic> _allocateOutput(List<int> shape) {
    if (shape.length == 3) {
      return List.generate(
        shape[0],
        (_) => List.generate(shape[1], (_) => List.filled(shape[2], 0.0)),
      );
    }
    throw StateError('Unsupported output shape: $shape');
  }

  List<double> _flattenChannelMajor(
      List<dynamic> output, int channels, int numPreds) {
    final flat = <double>[];
    for (int c = 0; c < channels; c++) {
      for (int i = 0; i < numPreds; i++) {
        flat.add((output[0][c][i] as num).toDouble());
      }
    }
    return flat;
  }

  List<double> _transposeThenFlatten(
      List<dynamic> output, int numPreds, int channels) {
    final flat = List<double>.filled(channels * numPreds, 0.0);
    for (int c = 0; c < channels; c++) {
      for (int i = 0; i < numPreds; i++) {
        flat[c * numPreds + i] = (output[0][i][c] as num).toDouble();
      }
    }
    return flat;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
