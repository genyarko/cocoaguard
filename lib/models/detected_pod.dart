import 'dart:typed_data';

import 'bounding_box.dart';
import 'diagnosis_result.dart';

class DetectedPod {
  final BoundingBox box;
  final DiagnosisResult diagnosis;
  final Uint8List? cropBytes;

  DetectedPod({
    required this.box,
    required this.diagnosis,
    this.cropBytes,
  });

  bool get isDiseased => diagnosis.className != 'healthy';

  /// True if primary OR alternative diagnosis suggests disease.
  bool get hasDiseaseSignal =>
      isDiseased ||
      (diagnosis.alternative != null &&
          diagnosis.alternative!.className != 'healthy');

  double get area => box.width * box.height;
}

class DetectionResult {
  final List<DetectedPod> pods;
  final Uint8List? imageBytes;
  final int imageWidth;
  final int imageHeight;
  final DateTime timestamp;

  DetectionResult({
    required this.pods,
    required this.imageWidth,
    required this.imageHeight,
    required this.timestamp,
    this.imageBytes,
  });

  /// Pods sorted by disease-priority: diseased first, then pods with disease
  /// alternatives, then healthy. Within each group, by confidence descending.
  List<DetectedPod> get podsByPriority {
    int diseaseRank(DetectedPod p) {
      if (p.isDiseased) return 0;
      if (p.hasDiseaseSignal) return 1;
      return 2;
    }

    final sorted = List<DetectedPod>.from(pods);
    sorted.sort((a, b) {
      final rankCmp = diseaseRank(a).compareTo(diseaseRank(b));
      if (rankCmp != 0) return rankCmp;
      return b.diagnosis.confidence.compareTo(a.diagnosis.confidence);
    });
    return sorted;
  }

  /// The pod with the largest bounding box area.
  DetectedPod? get largestPod {
    if (pods.isEmpty) return null;
    return pods.reduce((a, b) => a.area > b.area ? a : b);
  }

  /// All pods classified as diseased.
  List<DetectedPod> get diseasedPods =>
      pods.where((p) => p.isDiseased).toList();

  /// The most severe disease detection (highest confidence diseased pod).
  DetectedPod? get worstDisease {
    final diseased = diseasedPods;
    if (diseased.isEmpty) return null;
    return diseased.reduce(
        (a, b) => a.diagnosis.confidence > b.diagnosis.confidence ? a : b);
  }
}
