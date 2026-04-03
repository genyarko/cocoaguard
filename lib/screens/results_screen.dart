import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scan_record.dart';
import '../providers/history_provider.dart';
import '../providers/qa_provider.dart';
import '../providers/scan_provider.dart';
import '../utils/constants.dart';
import '../utils/treatment_data.dart';
import '../widgets/confidence_bar.dart';
import '../widgets/diagnosis_card.dart';
import 'qa_screen.dart';

class ResultsScreen extends StatelessWidget {
  final ScanRecord? savedRecord;

  const ResultsScreen({super.key, this.savedRecord});

  @override
  Widget build(BuildContext context) {
    if (savedRecord != null) {
      return _buildFromRecord(context, savedRecord!);
    }

    return Consumer<ScanProvider>(
      builder: (context, scanProvider, _) {
        final result = scanProvider.currentResult;
        final image = scanProvider.currentImage;

        if (result == null || image == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Result')),
            body: const Center(child: Text('No result available.')),
          );
        }

        return _buildResultScaffold(
          context,
          imageWidget: Image.file(
            image,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          diagnosis: result.diagnosis,
          confidence: result.confidence,
          scoreMap: result.scoreMap,
          showActions: true,
          scanType: 'leaf',
          qualityWarnings: scanProvider.qualityWarnings,
          isPotentiallyInfected: result.isPotentiallyInfected,
        );
      },
    );
  }

  Widget _buildFromRecord(BuildContext context, ScanRecord record) {
    final imageFile = File(record.imagePath);

    // Reconstruct scoreMap from stored allScores + label list
    final classNames = record.scanType == 'pod'
        ? ['carmenta', 'healthy', 'moniliasis', 'phytophthora', 'witches_broom']
        : ['anthracnose', 'cssvd', 'healthy'];
    final scoreMap = <String, double>{};
    for (var i = 0; i < classNames.length && i < record.allScores.length; i++) {
      scoreMap[classNames[i]] = record.allScores[i];
    }

    return _buildResultScaffold(
      context,
      imageWidget: imageFile.existsSync()
          ? Image.file(imageFile, height: 250, width: double.infinity, fit: BoxFit.cover)
          : Container(
              height: 250,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.image_not_supported, size: 64),
              ),
            ),
      diagnosis: record.diagnosis,
      confidence: record.confidence,
      scoreMap: scoreMap,
      showActions: false,
      scanType: record.scanType,
    );
  }

  Widget _buildResultScaffold(
    BuildContext context, {
    required Widget imageWidget,
    required String diagnosis,
    required double confidence,
    required Map<String, double> scoreMap,
    required bool showActions,
    required String scanType,
    List<String> qualityWarnings = const [],
    bool isPotentiallyInfected = false,
  }) {
    final treatmentInfo = leafTreatments[diagnosis] ?? podTreatments[diagnosis];
    final diagColor = AppConstants.colorForDiagnosis(diagnosis);

    return Scaffold(
      appBar: AppBar(
        title: Text('${scanType[0].toUpperCase()}${scanType.substring(1)} Result'),
        backgroundColor: diagColor.withValues(alpha: 0.1),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipRRect(child: imageWidget),

            // Image quality warnings
            if (qualityWarnings.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.image_not_supported_outlined, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Image Quality Issues',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.orange),
                          ),
                          const SizedBox(height: 2),
                          ...qualityWarnings.map((w) => Text(
                                '• $w',
                                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DiagnosisCard(diagnosis: diagnosis, confidence: confidence),

                  // Potentially infected warning (CSSVD >= 30% threshold)
                  if (isPotentiallyInfected) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.health_and_safety, color: Colors.red, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Potentially Infected',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'CSSVD detected at ${(confidence * 100).toStringAsFixed(1)}%. '
                                  'Although not the highest-scoring class, this level warrants '
                                  'further inspection by an expert.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Low-confidence warning (Phase 6.2)
                  if (confidence < 0.55) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Low Confidence Result',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'This result is uncertain (${(confidence * 100).toStringAsFixed(1)}%). '
                                  'Consider retaking the photo with better lighting and focus.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Confidence bars
                  Text(
                    'Class Scores',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...scoreMap.entries.map((e) => ConfidenceBar(
                        label: e.key,
                        score: e.value,
                        color: AppConstants.colorForDiagnosis(e.key),
                      )),

                  // Action buttons
                  if (showActions) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.read<ScanProvider>().clear();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Scan Another'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              final scanProv = context.read<ScanProvider>();
                              final histProv = context.read<HistoryProvider>();
                              final messenger = ScaffoldMessenger.of(context);
                              await scanProv.saveCurrentResult();
                              histProv.loadHistory();
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Result saved!')),
                              );
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Save Result'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Ask about this disease (context-aware Q&A)
                  if (showActions && diagnosis != 'healthy') ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<QaProvider>().setScanContext(
                              disease: diagnosis,
                              confidence: confidence * 100,
                              scanType: scanType,
                            );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QaScreen(
                              initialQuestion:
                                  'My cocoa $scanType was detected with $diagnosis '
                                  '(${(confidence * 100).toStringAsFixed(1)}% confidence). '
                                  'What causes this and how should I treat it?',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.smart_toy_outlined),
                      label: const Text('Ask about this disease'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                  ],

                  // Treatment recommendations
                  if (treatmentInfo != null) ...[
                    const SizedBox(height: 24),
                    _TreatmentSection(
                      diagnosis: diagnosis,
                      treatmentInfo: treatmentInfo,
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreatmentSection extends StatelessWidget {
  final String diagnosis;
  final Map<String, dynamic> treatmentInfo;

  const _TreatmentSection({
    required this.diagnosis,
    required this.treatmentInfo,
  });

  @override
  Widget build(BuildContext context) {
    final severity = treatmentInfo['severity'] as String;
    final recommendations = treatmentInfo['recommendations'] as List;
    final color = AppConstants.colorForDiagnosis(diagnosis);

    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      title: Text(
        'Treatment & Recommendations',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      children: [
        if (severity != 'none')
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Severity: ${severity[0].toUpperCase()}${severity.substring(1)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ...recommendations.map(
          (rec) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right, color: color, size: 20),
                const SizedBox(width: 4),
                Expanded(child: Text(rec as String)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
