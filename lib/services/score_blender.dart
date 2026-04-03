import 'dart:math' as math;

/// Blends YOLO detection class scores with EfficientNetB3 classification
/// probabilities using a weighted geometric mean.
///
/// When both models agree on the disease class, confidence increases.
/// When they disagree, the blended score is tempered.
class ScoreBlender {
  /// Index of the "healthy" class in the pod label list.
  static const int healthyClassIndex = 1;

  static const double _classifierWeightDefault = 0.75;
  static const double _detectorWeightDefault = 0.25;
  static const double _classifierWeightAgreed = 0.65;
  static const double _detectorWeightAgreed = 0.35;
  static const double _healthyDampening = 0.85;
  static const double _diseasePriorityThreshold = 0.40;

  /// Blends two probability vectors into a single fused probability vector.
  ///
  /// [classifierProbs] — softmax probabilities from EfficientNetB3 (sum to ~1)
  /// [detectorScores]  — raw class scores from YOLO (not normalized)
  static List<double> blend(
    List<double> classifierProbs,
    List<double> detectorScores,
  ) {
    final n = classifierProbs.length;
    if (detectorScores.length != n) return classifierProbs;

    final detectorSum = detectorScores.fold(0.0, (a, b) => a + b);
    final detectorProbs = detectorSum > 0
        ? detectorScores.map((s) => s / detectorSum).toList()
        : detectorScores;

    final classifierTop = _argmax(classifierProbs);
    final detectorTop = _argmax(detectorProbs);
    final modelsAgree = classifierTop == detectorTop;

    final cw = modelsAgree ? _classifierWeightAgreed : _classifierWeightDefault;
    final dw = modelsAgree ? _detectorWeightAgreed : _detectorWeightDefault;

    final classifierTopDisease = _topDiseaseScore(classifierProbs);
    final detectorTopDisease = _topDiseaseScore(detectorProbs);
    final diseaseSignal = math.max(classifierTopDisease, detectorTopDisease);

    final blended = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final cp = math.max(classifierProbs[i], 1e-10);
      final dp = math.max(detectorProbs[i], 1e-10);
      var score =
          math.pow(cp, cw).toDouble() * math.pow(dp, dw).toDouble();

      if (i == healthyClassIndex && diseaseSignal > _diseasePriorityThreshold) {
        score *= _healthyDampening;
      }

      blended[i] = score;
    }

    final sum = blended.fold(0.0, (a, b) => a + b);
    if (sum > 0) {
      for (int i = 0; i < n; i++) {
        blended[i] /= sum;
      }
    }

    return blended;
  }

  static int _argmax(List<double> values) {
    int best = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return best;
  }

  static double _topDiseaseScore(List<double> probs) {
    double top = 0.0;
    for (int i = 0; i < probs.length; i++) {
      if (i != healthyClassIndex && probs[i] > top) top = probs[i];
    }
    return top;
  }
}
