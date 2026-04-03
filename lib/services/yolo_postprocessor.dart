import 'dart:math' as math;

import '../models/bounding_box.dart';
import 'yolo_preprocessor.dart';

class YoloPostprocessor {
  static const int numClasses = 5;
  static const double defaultConfidenceThreshold = 0.20;
  static const double defaultIouThreshold = 0.45;

  /// Decodes YOLO output into a list of bounding boxes in original image coordinates.
  static List<BoundingBox> process({
    required List<double> rawOutput,
    required LetterboxInfo letterbox,
    int channels = 9,
    int numPreds = 8400,
    int inputSize = 640,
    double confidenceThreshold = defaultConfidenceThreshold,
    double iouThreshold = defaultIouThreshold,
  }) {
    final List<BoundingBox> candidates = [];

    final bool normalized = _isNormalized(rawOutput, numPreds);
    final double coordScale = normalized ? inputSize.toDouble() : 1.0;

    for (int i = 0; i < numPreds; i++) {
      final double cx = rawOutput[0 * numPreds + i] * coordScale;
      final double cy = rawOutput[1 * numPreds + i] * coordScale;
      final double w = rawOutput[2 * numPreds + i] * coordScale;
      final double h = rawOutput[3 * numPreds + i] * coordScale;

      final classScores = <double>[];
      int bestClass = 0;
      double bestScore = rawOutput[4 * numPreds + i];
      classScores.add(bestScore);
      for (int c = 1; c < numClasses; c++) {
        final double score = rawOutput[(4 + c) * numPreds + i];
        classScores.add(score);
        if (score > bestScore) {
          bestScore = score;
          bestClass = c;
        }
      }

      if (bestScore < confidenceThreshold) continue;

      double left = cx - w / 2.0;
      double top = cy - h / 2.0;
      double right = cx + w / 2.0;
      double bottom = cy + h / 2.0;

      left = (left - letterbox.padX) / letterbox.scale;
      right = (right - letterbox.padX) / letterbox.scale;
      top = (top - letterbox.padY) / letterbox.scale;
      bottom = (bottom - letterbox.padY) / letterbox.scale;

      left = left.clamp(0.0, letterbox.origWidth.toDouble());
      right = right.clamp(0.0, letterbox.origWidth.toDouble());
      top = top.clamp(0.0, letterbox.origHeight.toDouble());
      bottom = bottom.clamp(0.0, letterbox.origHeight.toDouble());

      if (right <= left || bottom <= top) continue;

      candidates.add(BoundingBox(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        confidence: bestScore,
        classIndex: bestClass,
        classScores: classScores,
      ));
    }

    return _nms(candidates, iouThreshold);
  }

  static bool _isNormalized(List<double> rawOutput, int numPreds) {
    double maxCoord = 0.0;
    final step = math.max(1, numPreds ~/ 100);
    for (int i = 0; i < numPreds; i += step) {
      final w = rawOutput[2 * numPreds + i];
      final h = rawOutput[3 * numPreds + i];
      if (w > maxCoord) maxCoord = w;
      if (h > maxCoord) maxCoord = h;
    }
    return maxCoord <= 1.5;
  }

  static List<BoundingBox> _nms(
      List<BoundingBox> detections, double iouThreshold) {
    final results = <BoundingBox>[];
    final byClass = <int, List<BoundingBox>>{};
    for (final d in detections) {
      byClass.putIfAbsent(d.classIndex, () => []).add(d);
    }

    for (final dets in byClass.values) {
      dets.sort((a, b) => b.confidence.compareTo(a.confidence));
      final removed = List<bool>.filled(dets.length, false);
      for (int i = 0; i < dets.length; i++) {
        if (removed[i]) continue;
        results.add(dets[i]);
        for (int j = i + 1; j < dets.length; j++) {
          if (removed[j]) continue;
          if (_iou(dets[i], dets[j]) > iouThreshold) removed[j] = true;
        }
      }
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  static double _iou(BoundingBox a, BoundingBox b) {
    final interLeft = math.max(a.left, b.left);
    final interTop = math.max(a.top, b.top);
    final interRight = math.min(a.right, b.right);
    final interBottom = math.min(a.bottom, b.bottom);

    final interW = math.max(0.0, interRight - interLeft);
    final interH = math.max(0.0, interBottom - interTop);
    final interArea = interW * interH;

    final areaA = (a.right - a.left) * (a.bottom - a.top);
    final areaB = (b.right - b.left) * (b.bottom - b.top);
    final union = areaA + areaB - interArea;

    if (union <= 0.0) return 0.0;
    return interArea / union;
  }
}
