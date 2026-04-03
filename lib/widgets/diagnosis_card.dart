import 'package:flutter/material.dart';

import '../utils/constants.dart';

class DiagnosisCard extends StatelessWidget {
  final String diagnosis;
  final double confidence;

  const DiagnosisCard({
    super.key,
    required this.diagnosis,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.colorForDiagnosis(diagnosis);
    final isLowConfidence = confidence < AppConstants.confidenceThreshold;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(_iconForDiagnosis(diagnosis), size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              displayNameForDiagnosis(diagnosis),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(confidence * 100).toStringAsFixed(1)}% confidence',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            if (isLowConfidence) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Low confidence — try a clearer photo',
                        style: TextStyle(color: Colors.amber, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForDiagnosis(String diagnosis) {
    switch (diagnosis) {
      case 'healthy':
        return Icons.check_circle_outline;
      case 'cssvd':
        return Icons.dangerous_outlined;
      default:
        return Icons.warning_outlined;
    }
  }

  static String displayNameForDiagnosis(String diagnosis) {
    switch (diagnosis) {
      case 'anthracnose':
        return 'Anthracnose (Black Pod)';
      case 'cssvd':
        return 'CSSVD';
      case 'healthy':
        return 'Healthy';
      case 'phytophthora':
        return 'Phytophthora (Black Pod Rot)';
      case 'carmenta':
        return 'Carmenta (Pod Borer)';
      case 'moniliasis':
        return 'Moniliasis (Frosty Pod)';
      case 'witches_broom':
        return "Witches' Broom";
      default:
        return diagnosis;
    }
  }
}
