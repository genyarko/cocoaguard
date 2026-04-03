import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

/// Result of an image quality check.
class ImageQualityResult {
  final bool isAcceptable;
  final List<String> warnings;

  /// Brightness on 0–255 scale.
  final double brightness;

  /// Blur score (Laplacian variance). Higher = sharper.
  final double sharpness;

  /// Image dimensions.
  final int width;
  final int height;

  const ImageQualityResult({
    required this.isAcceptable,
    required this.warnings,
    required this.brightness,
    required this.sharpness,
    required this.width,
    required this.height,
  });
}

/// Lightweight image quality checks for blur, brightness, and size.
///
/// Runs on a down-sampled copy to keep latency low on mid-range devices.
class ImageQualityChecker {
  // Thresholds
  static const double _minBrightness = 40.0;
  static const double _maxBrightness = 235.0;
  static const double _minSharpness = 50.0;
  static const int _minDimension = 224;

  /// Check quality of an image file. Returns quickly by down-sampling first.
  static Future<ImageQualityResult> check(File file) async {
    final bytes = await file.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) {
      return const ImageQualityResult(
        isAcceptable: false,
        warnings: ['Could not read image. Please try another photo.'],
        brightness: 0,
        sharpness: 0,
        width: 0,
        height: 0,
      );
    }

    final warnings = <String>[];

    // Dimension check on original
    if (original.width < _minDimension || original.height < _minDimension) {
      warnings.add('Image is too small. Use a higher resolution.');
    }

    // Down-sample for speed (max 256px on longest side)
    final small = img.copyResize(
      original,
      width: original.width > original.height ? 256 : null,
      height: original.height >= original.width ? 256 : null,
      interpolation: img.Interpolation.average,
    );

    // Convert to grayscale for analysis
    final gray = img.grayscale(small);

    // Brightness: mean pixel value
    final brightness = _meanBrightness(gray);
    if (brightness < _minBrightness) {
      warnings.add('Image is too dark. Try better lighting.');
    } else if (brightness > _maxBrightness) {
      warnings.add('Image is overexposed. Reduce glare or direct sunlight.');
    }

    // Sharpness: Laplacian variance (higher = sharper)
    final sharpness = _laplacianVariance(gray);
    if (sharpness < _minSharpness) {
      warnings.add('Image appears blurry. Hold steady and tap to focus.');
    }

    return ImageQualityResult(
      isAcceptable: warnings.isEmpty,
      warnings: warnings,
      brightness: brightness,
      sharpness: sharpness,
      width: original.width,
      height: original.height,
    );
  }

  static double _meanBrightness(img.Image gray) {
    double sum = 0;
    final numPixels = gray.width * gray.height;
    for (final pixel in gray) {
      sum += pixel.r; // grayscale so r == g == b
    }
    return sum / numPixels;
  }

  /// Laplacian variance as a blur metric.
  /// Applies a 3×3 Laplacian kernel and returns the variance of the output.
  static double _laplacianVariance(img.Image gray) {
    final w = gray.width;
    final h = gray.height;
    if (w < 3 || h < 3) return 0;

    // Get pixel luminance as flat array for fast access
    final pixels = List<int>.generate(
      w * h,
      (i) => gray.getPixel(i % w, i ~/ w).r.toInt(),
    );

    double sum = 0;
    double sumSq = 0;
    int count = 0;

    // Laplacian kernel: [0, 1, 0], [1, -4, 1], [0, 1, 0]
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final lap = -4 * pixels[y * w + x] +
            pixels[(y - 1) * w + x] +
            pixels[(y + 1) * w + x] +
            pixels[y * w + (x - 1)] +
            pixels[y * w + (x + 1)];

        sum += lap;
        sumSq += lap * lap;
        count++;
      }
    }

    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);
    return max(0, variance);
  }
}
