class BoundingBox {
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double confidence;
  final int classIndex;

  /// Raw class scores from the YOLO detector (one per class).
  final List<double> classScores;

  BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.confidence,
    required this.classIndex,
    required this.classScores,
  });

  double get width => right - left;
  double get height => bottom - top;
}
