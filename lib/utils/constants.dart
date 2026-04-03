import 'package:flutter/material.dart';

class AppConstants {
  // App
  static const String appName = 'CocoaGuard';

  // Leaf model
  static const String leafModelPath = 'assets/models/leaf_classifier.tflite';
  static const String leafLabelsPath = 'assets/models/leaf_labels.json';

  // Pod model (used in Phase 2)
  static const String podModelPath = 'assets/models/pod_classifier.tflite';
  static const String podLabelsPath = 'assets/models/pod_labels.json';
  static const String yoloModelPath = 'assets/models/yolo_pod_detect.tflite';

  // Inference
  static const int inputSize = 300;
  static const double confidenceThreshold = 0.70;

  // Leaf disease colors
  static const Color healthyColor = Color(0xFF4CAF50);
  static const Color anthracnoseColor = Color(0xFFFF9800);
  static const Color cssvdColor = Color(0xFFF44336);

  // Pod disease colors
  static const Color phytophthoraColor = Color(0xFFD32F2F);
  static const Color carmentaColor = Color(0xFFE65100);
  static const Color moniliasisColor = Color(0xFFFFC107);
  static const Color witchesBroomColor = Color(0xFF9C27B0);

  static Color colorForDiagnosis(String diagnosis) {
    switch (diagnosis) {
      case 'healthy':
        return healthyColor;
      case 'anthracnose':
        return anthracnoseColor;
      case 'cssvd':
        return cssvdColor;
      case 'phytophthora':
        return phytophthoraColor;
      case 'carmenta':
        return carmentaColor;
      case 'moniliasis':
        return moniliasisColor;
      case 'witches_broom':
        return witchesBroomColor;
      default:
        return Colors.grey;
    }
  }
}
