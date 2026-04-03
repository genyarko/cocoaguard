import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Builds TFLite [InterpreterOptions] with the best available delegate.
///
/// Strategy (Android):
///   1. NNAPI  — routes to DSP/NPU hardware accelerator when available
///   2. GPU    — GpuDelegateV2, accelerates convolutions on device GPU
///   3. CPU    — 4 threads fallback
///
/// NNAPI is preferred because it automatically selects the fastest hardware
/// (NPU > DSP > GPU > CPU) on modern Android devices. GPU is tried next for
/// devices without NPU. Float16 models work on both.
class InterpreterOptionsBuilder {
  static const int _cpuThreads = 4;

  /// Returns options configured with the fastest available delegate.
  /// Never throws — always returns a usable [InterpreterOptions].
  static InterpreterOptions build({String label = ''}) {
    final tag = label.isEmpty ? '' : '/$label';

    if (Platform.isAndroid) {
      // 1. Try NNAPI
      try {
        final opts = InterpreterOptions()..useNnApiForAndroid = true;
        debugPrint('[DELEGATE$tag] Using NNAPI');
        return opts;
      } catch (_) {}

      // 2. Try GPU delegate (GpuDelegateV2 — Android only)
      try {
        final opts = InterpreterOptions()
          ..addDelegate(GpuDelegateV2());
        debugPrint('[DELEGATE$tag] Using GPU');
        return opts;
      } catch (_) {}
    }

    // 3. CPU multi-threaded fallback
    debugPrint('[DELEGATE$tag] Using CPU ($_cpuThreads threads)');
    return InterpreterOptions()..threads = _cpuThreads;
  }
}
