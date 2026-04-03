import 'package:flutter/material.dart';

import '../models/detected_pod.dart';
import '../utils/constants.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<DetectedPod> pods;
  final int imageWidth;
  final int imageHeight;

  const BoundingBoxPainter({
    required this.pods,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    for (final pod in pods) {
      final box = pod.box;
      final color = AppConstants.colorForDiagnosis(pod.diagnosis.className);

      final rect = Rect.fromLTRB(
        box.left * scaleX,
        box.top * scaleY,
        box.right * scaleX,
        box.bottom * scaleY,
      );

      // Box outline
      canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      // Label text
      final label =
          '${pod.diagnosis.displayName} ${(pod.diagnosis.confidence * 100).toStringAsFixed(0)}%';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );

      canvas.drawRect(labelRect, Paint()..color = color);
      textPainter.paint(
          canvas, Offset(rect.left + 4, rect.top - textPainter.height - 2));
    }
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) =>
      oldDelegate.pods != pods;
}
