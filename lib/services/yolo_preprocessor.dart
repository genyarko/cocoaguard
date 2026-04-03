import 'dart:typed_data';
import 'package:image/image.dart' as img;

class LetterboxInfo {
  final double scale;
  final double padX;
  final double padY;
  final int origWidth;
  final int origHeight;

  LetterboxInfo({
    required this.scale,
    required this.padX,
    required this.padY,
    required this.origWidth,
    required this.origHeight,
  });
}

class YoloPreprocessor {
  static const int inputSize = 640;

  /// Letterbox-resizes the image to 640×640 and normalizes to [0, 1].
  /// [nchw] controls memory layout:
  ///   true  → [1, 3, 640, 640] (channel-first)
  ///   false → [1, 640, 640, 3] (channel-last, default TFLite)
  static (Float32List, LetterboxInfo) process(img.Image image,
      {bool nchw = false}) {
    final origW = image.width;
    final origH = image.height;

    final scale = (inputSize / origW) < (inputSize / origH)
        ? inputSize / origW
        : inputSize / origH;

    final scaledW = (origW * scale).round();
    final scaledH = (origH * scale).round();
    final padX = (inputSize - scaledW) / 2.0;
    final padY = (inputSize - scaledH) / 2.0;

    final resized = img.copyResize(
      image,
      width: scaledW,
      height: scaledH,
      interpolation: img.Interpolation.linear,
    );

    final canvas = img.Image(width: inputSize, height: inputSize, numChannels: 3);
    img.fill(canvas, color: img.ColorRgb8(114, 114, 114));
    img.compositeImage(canvas, resized, dstX: padX.round(), dstY: padY.round());

    final buffer = Float32List(1 * inputSize * inputSize * 3);

    if (nchw) {
      final planeSize = inputSize * inputSize;
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = canvas.getPixel(x, y);
          final idx = y * inputSize + x;
          buffer[0 * planeSize + idx] = pixel.r.toDouble() / 255.0;
          buffer[1 * planeSize + idx] = pixel.g.toDouble() / 255.0;
          buffer[2 * planeSize + idx] = pixel.b.toDouble() / 255.0;
        }
      }
    } else {
      int offset = 0;
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = canvas.getPixel(x, y);
          buffer[offset++] = pixel.r.toDouble() / 255.0;
          buffer[offset++] = pixel.g.toDouble() / 255.0;
          buffer[offset++] = pixel.b.toDouble() / 255.0;
        }
      }
    }

    return (
      buffer,
      LetterboxInfo(
        scale: scale,
        padX: padX,
        padY: padY,
        origWidth: origW,
        origHeight: origH,
      ),
    );
  }
}
