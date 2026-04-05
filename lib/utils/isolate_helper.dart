import 'dart:isolate';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

/// Runs a computation in a background isolate to avoid blocking the UI thread.
///
/// This keeps the spinner/loading dialog responsive while heavy work happens.
/// Completes with the result of [computation].
Future<T> runInBackground<T>(
  T Function() computation, {
  String? label,
}) async {
  return await compute(
    (msg) => computation(),
    null,
    debugLabel: label,
  );
}

/// Wrapper for image decoding in background isolate.
/// Since TFLite interpreters can't cross isolates, this pre-processes the image
/// on a background thread, then passes it back for inference on the main thread.
Future<img.Image?> decodeImageInBackground(List<int> bytes) async {
  return await compute(_decodeImage, bytes);
}

img.Image? _decodeImage(List<int> bytes) {
  try {
    return img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
}
