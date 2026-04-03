# TensorFlow Lite — keep GPU delegate classes that R8 would otherwise strip
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
