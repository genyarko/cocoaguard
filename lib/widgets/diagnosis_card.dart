import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/knowledge_service.dart';
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
    final lang = context.watch<LanguageProvider>();
    final ks = lang.knowledgeService;
    final color = AppConstants.colorForDiagnosis(diagnosis);
    final isDiseased = diagnosis != 'healthy';
    // Disease names always red for visibility; healthy stays green
    final nameColor = isDiseased ? Colors.red[700]! : color;
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
            Icon(_iconForDiagnosis(diagnosis), size: 48, color: nameColor),
            const SizedBox(height: 12),
            Text(
              translatedDiagnosisName(diagnosis, ks),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: nameColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(confidence * 100).toStringAsFixed(1)}% ${ks.sectionTitle('confidence')}',
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        ks.sectionTitle('lowConfidenceTip'),
                        style: const TextStyle(color: Colors.amber, fontSize: 13),
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

  /// Map disease id to its label key in KnowledgeService.
  static const _diagnosisLabelKeys = {
    'anthracnose': 'diseaseAnthracnose',
    'cssvd': 'diseaseCssvd',
    'healthy': 'diseaseHealthy',
    'phytophthora': 'diseasePhytophthora',
    'carmenta': 'diseaseCarmenta',
    'moniliasis': 'diseaseMoniliasis',
    'witches_broom': 'diseaseWitchesBroom',
  };

  /// Get the translated disease display name from KnowledgeService labels.
  static String translatedDiagnosisName(
      String diagnosis, KnowledgeService ks) {
    final key = _diagnosisLabelKeys[diagnosis];
    if (key == null) return diagnosis;
    return ks.sectionTitle(key);
  }

  /// Legacy helper for contexts without KnowledgeService (English only).
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
