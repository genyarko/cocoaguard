import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Builds TFLite [InterpreterOptions] with optional hardware acceleration.
///
/// Default behavior: CPU-only (safe, always works)
/// Call [enableDelegates] at app startup to opt-in to NNAPI/GPU.
///
/// Strategy when delegates enabled (Android):
///   1. NNAPI  — routes to DSP/NPU hardware accelerator when available
///   2. GPU    — GpuDelegateV2, accelerates convolutions on device GPU
///   3. CPU    — 4 threads fallback if delegates fail
class InterpreterOptionsBuilder {
  static const int _cpuThreads = 4;
  static bool _useDelegates = false;

  /// Enable hardware accelerators (NNAPI/GPU). Call at app startup if desired.
  /// ⚠️ Delegates can cause compatibility issues — only use if tests pass on your device.
  static void enableDelegates() {
    _useDelegates = true;
    debugPrint('[DELEGATE] Hardware accelerators enabled (NNAPI/GPU)');
  }

  /// Disable hardware accelerators, use CPU-only. Safe fallback if crashes occur.
  static void disableDelegates() {
    _useDelegates = false;
    debugPrint('[DELEGATE] Hardware accelerators disabled — CPU-only mode');
  }

  /// Returns options configured with the best available delegate.
  /// Never throws — always returns a usable [InterpreterOptions].
  static InterpreterOptions build({String label = ''}) {
    final tag = label.isEmpty ? '' : '/$label';

    // Default: CPU-only (safe, always works)
    if (!_useDelegates || !Platform.isAndroid) {
      debugPrint('[DELEGATE$tag] Using CPU ($_cpuThreads threads)');
      return InterpreterOptions()..threads = _cpuThreads;
    }

    // Only try hardware accelerators if explicitly enabled
    if (Platform.isAndroid) {
      // 1. Try NNAPI
      try {
        final opts = InterpreterOptions()..useNnApiForAndroid = true;
        debugPrint('[DELEGATE$tag] Using NNAPI');
        return opts;
      } catch (e) {
        debugPrint('[DELEGATE$tag] NNAPI failed: $e — falling back to CPU');
      }

      // 2. Try GPU delegate
      try {
        final opts = InterpreterOptions()
          ..addDelegate(GpuDelegateV2());
        debugPrint('[DELEGATE$tag] Using GPU delegate');
        return opts;
      } catch (e) {
        debugPrint('[DELEGATE$tag] GPU failed: $e — falling back to CPU');
      }
    }

    // 3. CPU multi-threaded fallback (always works)
    debugPrint('[DELEGATE$tag] Using CPU ($_cpuThreads threads)');
    return InterpreterOptions()..threads = _cpuThreads;
  }
}
