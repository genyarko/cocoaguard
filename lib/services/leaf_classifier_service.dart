import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../utils/constants.dart';
import '../utils/image_utils.dart';

class LeafClassificationResult {
  final String diagnosis;
  final double confidence;
  final List<double> allScores;
  final Map<String, double> scoreMap;

  LeafClassificationResult({
    required this.diagnosis,
    required this.confidence,
    required this.allScores,
    required this.scoreMap,
  });
}

class LeafClassifierService {
  Interpreter? _interpreter;
  List<String> _classNames = [];

  bool get isReady => _interpreter != null && _classNames.isNotEmpty;

  Future<void> init() async {
    _interpreter = await Interpreter.fromAsset(AppConstants.leafModelPath);

    final labelsJson = await rootBundle.loadString(AppConstants.leafLabelsPath);
    final labelsData = json.decode(labelsJson) as Map<String, dynamic>;
    _classNames = List<String>.from(labelsData['class_names']);
  }

  LeafClassificationResult classify(File imageFile) {
    if (!isReady) throw StateError('Leaf classifier not initialized. Call init() first.');

    final image = ImageUtils.preprocessFile(imageFile);
    final input = ImageUtils.imageToFloat32Tensor(image);

    // Reshape input to [1, 300, 300, 3]
    final inputTensor = input.reshape([1, 300, 300, 3]);

    // Output buffer [1, numClasses]
    final output = List.filled(1 * _classNames.length, 0.0).reshape([1, _classNames.length]);

    _interpreter!.run(inputTensor, output);

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

    return LeafClassificationResult(
      diagnosis: _classNames[maxIdx],
      confidence: scores[maxIdx],
      allScores: scores,
      scoreMap: scoreMap,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
