import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageUtils {
  /// Decode an image file, center-crop to square, and resize to 300×300.
  static img.Image preprocessFile(File file) {
    final bytes = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image');

    final cropped = _centerCropToSquare(decoded);
    return img.copyResize(cropped, width: 300, height: 300);
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
