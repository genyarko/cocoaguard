import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageUtils {
  /// Maximum dimension (width or height) for images entering the pipeline.
  /// Camera photos can be 4000+ px; downscaling first saves memory and time.
  static const int maxInputDimension = 1280;

  /// Decode an image file, center-crop to square, and resize to 300×300.
  static img.Image preprocessFile(File file) {
    final bytes = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image');

    final downscaled = constrainSize(decoded);
    final cropped = _centerCropToSquare(downscaled);
    return img.copyResize(cropped, width: 300, height: 300);
  }

  /// Downscale an image so its longest side is at most [maxInputDimension].
  /// Returns the original if already within bounds.
  static img.Image constrainSize(img.Image image,
      {int maxDim = maxInputDimension}) {
    final longest =
        image.width > image.height ? image.width : image.height;
    if (longest <= maxDim) return image;

    final scale = maxDim / longest;
    return img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }

  /// Center-crop to the largest inscribed square.
  static img.Image _centerCropToSquare(img.Image image) {
    final side = image.width < image.height ? image.width : image.height;
    final x = (image.width - side) ~/ 2;
    final y = (image.height - side) ~/ 2;
    return img.copyCrop(image, x: x, y: y, width: side, height: side);
  }

  /// Convert a 300×300 image to a Float32List shaped [1, 300, 300, 3].
  /// Pixel values kept as 0–255 (no normalization).
  static Float32List imageToFloat32Tensor(img.Image image) {
    final tensor = Float32List(1 * 300 * 300 * 3);
    var index = 0;
    for (var y = 0; y < 300; y++) {
      for (var x = 0; x < 300; x++) {
        final pixel = image.getPixel(x, y);
        tensor[index++] = pixel.r.toDouble();
        tensor[index++] = pixel.g.toDouble();
        tensor[index++] = pixel.b.toDouble();
      }
    }
    return tensor;
  }
}
