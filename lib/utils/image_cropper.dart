import 'dart:math' as math;
import 'package:image/image.dart' as img;

import '../models/bounding_box.dart';

class ImageCropper {
  /// Crops the bounding box region from the source image with a small
  /// padding margin for context.
  static img.Image crop(img.Image source, BoundingBox box,
      {double padding = 0.05}) {
    final padW = (box.width * padding).round();
    final padH = (box.height * padding).round();

    final x = math.max(0, box.left.round() - padW);
    final y = math.max(0, box.top.round() - padH);
    final right = math.min(source.width, box.right.round() + padW);
    final bottom = math.min(source.height, box.bottom.round() + padH);

    final w = right - x;
    final h = bottom - y;

    if (w <= 0 || h <= 0) return source;

    return img.copyCrop(source, x: x, y: y, width: w, height: h);
  }
}
