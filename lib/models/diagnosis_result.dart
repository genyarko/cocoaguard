import 'dart:typed_data';

/// A secondary diagnosis that scored close to the primary one.
class AlternativeDiagnosis {
  final String className;
  final String displayName;
  final double confidence;

  AlternativeDiagnosis({
    required this.className,
    required this.displayName,
    required this.confidence,
  });
}

class DiagnosisResult {
  final String className;
  final String displayName;
  final double confidence;
  final bool isUncertain;
  final List<double> probabilities;
  final DateTime timestamp;
  final Uint8List? imageBytes;

  /// When the top two classes are close in confidence, this holds the
  /// runner-up as a differential diagnosis for the user to consider.
  final AlternativeDiagnosis? alternative;

  DiagnosisResult({
    required this.className,
    required this.displayName,
    required this.confidence,
    required this.isUncertain,
    required this.probabilities,
    required this.timestamp,
    this.imageBytes,
    this.alternative,
  });

  bool get hasAlternative => alternative != null;
}
