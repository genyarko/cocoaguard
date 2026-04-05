import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/detected_pod.dart';
import '../models/scan_record.dart';
import '../providers/history_provider.dart';
import '../providers/language_provider.dart';
import '../providers/pod_scan_provider.dart';
import '../providers/qa_provider.dart';
import '../utils/constants.dart';
import '../utils/treatment_data.dart';
import '../widgets/bounding_box_painter.dart';
import '../widgets/confidence_bar.dart';
import '../widgets/diagnosis_card.dart';
import 'qa_screen.dart';

class PodResultsScreen extends StatelessWidget {
  /// Non-null when opened from scan history (live detection data not available).
  final ScanRecord? savedRecord;

  const PodResultsScreen({super.key, this.savedRecord});

  @override
  Widget build(BuildContext context) {
    if (savedRecord != null) {
      return _buildFromRecord(context, savedRecord!);
    }

    return Consumer<PodScanProvider>(
      builder: (context, provider, _) {
        final result = provider.currentResult;
        final imageFile = provider.currentImage;
        final imageBytes = provider.currentImageBytes;

        if (result == null || imageFile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pod Result')),
            body: const Center(child: Text('No result available.')),
          );
        }

        return _buildLiveScaffold(
          context,
          result: result,
          imageBytes: imageBytes,
          imageFile: imageFile,
          qualityWarnings: provider.qualityWarnings,
        );
      },
    );
  }

  // ── History replay ──────────────────────────────────────────────────────────

  Widget _buildFromRecord(BuildContext context, ScanRecord record) {
    final lang = context.watch<LanguageProvider>();
    final ks = lang.knowledgeService;
    final imageFile = File(record.imagePath);
    const classNames = [
      'carmenta',
      'healthy',
      'moniliasis',
      'phytophthora',
      'witches_broom',
    ];
    final scoreMap = <String, double>{};
    for (var i = 0; i < classNames.length && i < record.allScores.length; i++) {
      scoreMap[classNames[i]] = record.allScores[i];
    }

    final color = AppConstants.colorForDiagnosis(record.diagnosis);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pod ${ks.sectionTitle('resultTitle')}'),
        backgroundColor: color.withValues(alpha: 0.1),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 260,
              child: imageFile.existsSync()
                  ? Image.file(imageFile, fit: BoxFit.cover, width: double.infinity)
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                          child: Icon(Icons.image_not_supported, size: 64)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DiagnosisCard(
                    diagnosis: record.diagnosis,
                    confidence: record.confidence,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ks.sectionTitle('classScores'),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...scoreMap.entries.map((e) => ConfidenceBar(
                        label: DiagnosisCard.translatedDiagnosisName(e.key, ks),
                        score: e.value,
                        color: AppConstants.colorForDiagnosis(e.key),
                      )),
                  const SizedBox(height: 16),
                  _TreatmentSection(diagnosis: record.diagnosis),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Live detection result ───────────────────────────────────────────────────

  Widget _buildLiveScaffold(
    BuildContext context, {
    required DetectionResult result,
    Uint8List? imageBytes,
    required File imageFile,
    List<String> qualityWarnings = const [],
  }) {
    final lang = context.watch<LanguageProvider>();
    final ks = lang.knowledgeService;
    final l = ks.sectionTitle;
    final diseasedCount = result.diseasedPods.length;
    final totalCount = result.pods.length;
    final summaryColor =
        diseasedCount > 0 ? Colors.red[700]! : Colors.green[700]!;

    return Scaffold(
      appBar: AppBar(title: Text('Pod ${l('resultTitle')}')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Annotated image with bounding boxes
            _AnnotatedImage(
              imageBytes: imageBytes,
              imageFile: imageFile,
              pods: result.pods,
              imageWidth: result.imageWidth,
              imageHeight: result.imageHeight,
            ),

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
                          Text(
                            l('imageQualityIssues'),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.orange),
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
                  // Summary banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: summaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: summaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          diseasedCount > 0
                              ? Icons.warning_amber
                              : Icons.check_circle,
                          color: summaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            diseasedCount > 0
                                ? '$diseasedCount / $totalCount pods — ${l('potentiallyInfected')}'
                                : '$totalCount pods — ${l('diseaseHealthy')}',
                            style: TextStyle(
                              color: summaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Low-confidence warning for uncertain pods
                  if (result.pods.any((p) => p.diagnosis.confidence < 0.55)) ...[
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
                                Text(
                                  l('lowConfidenceResult'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l('lowConfidenceHint'),
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

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<PodScanProvider>().clear();
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: Text(l('scanAnother')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final podProv = context.read<PodScanProvider>();
                            final histProv = context.read<HistoryProvider>();
                            final messenger = ScaffoldMessenger.of(context);
                            await podProv.saveCurrentResult();
                            histProv.loadHistory();
                            messenger.showSnackBar(
                              SnackBar(content: Text(l('resultSaved'))),
                            );
                          },
                          icon: const Icon(Icons.save),
                          label: Text(l('saveResult')),
                        ),
                      ),
                    ],
                  ),

                  // Ask about detected disease (context-aware Q&A)
                  if (result.diseasedPods.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        final topDisease = result.diseasedPods.first;
                        context.read<QaProvider>().setScanContext(
                              disease: topDisease.diagnosis.className,
                              confidence:
                                  topDisease.diagnosis.confidence * 100,
                              scanType: 'pod',
                            );

                        // Build a question listing all unique diseases found
                        final diseaseEntries = result.diseasedPods
                            .map((p) =>
                                '${p.diagnosis.className} '
                                '(${(p.diagnosis.confidence * 100).toStringAsFixed(1)}%)')
                            .toSet() // deduplicate
                            .toList();
                        final diseaseSummary = diseaseEntries.join(', ');
                        final question = diseaseEntries.length == 1
                            ? 'My cocoa pod was detected with $diseaseSummary. '
                                'What causes this and how should I treat it?'
                            : 'My cocoa pods show multiple diseases: $diseaseSummary. '
                                'What causes these and how should I treat them?';

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QaScreen(
                              initialQuestion: question,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.smart_toy_outlined),
                      label: Text(l('askAboutDisease')),
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size(double.infinity, 44),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Per-pod detail cards
                  Text(
                    'Pod Details (${result.pods.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  ...result.podsByPriority.asMap().entries.map(
                        (e) => _PodDetailCard(
                          pod: e.value,
                          podNumber: e.key + 1,
                        ),
                      ),

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

// ── Annotated image with exact bounding box overlay ─────────────────────────

class _AnnotatedImage extends StatelessWidget {
  final Uint8List? imageBytes;
  final File? imageFile;
  final List<DetectedPod> pods;
  final int imageWidth;
  final int imageHeight;

  const _AnnotatedImage({
    required this.pods,
    required this.imageWidth,
    required this.imageHeight,
    this.imageBytes,
    this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    const maxHeight = 300.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final imageAspect = imageWidth / imageHeight;
    final containerAspect = screenWidth / maxHeight;

    // Compute the actual rendered rect inside the contain-fit container
    double renderW, renderH, offsetX = 0, offsetY = 0;
    if (imageAspect > containerAspect) {
      // Fit by width
      renderW = screenWidth;
      renderH = screenWidth / imageAspect;
      offsetY = (maxHeight - renderH) / 2;
    } else {
      // Fit by height
      renderH = maxHeight;
      renderW = maxHeight * imageAspect;
      offsetX = (screenWidth - renderW) / 2;
    }

    Widget imageWidget;
    if (imageBytes != null) {
      imageWidget = Image.memory(
        imageBytes!,
        width: screenWidth,
        height: maxHeight,
        fit: BoxFit.contain,
      );
    } else if (imageFile != null && imageFile!.existsSync()) {
      imageWidget = Image.file(
        imageFile!,
        width: screenWidth,
        height: maxHeight,
        fit: BoxFit.contain,
      );
    } else {
      return Container(
        height: maxHeight,
        color: Colors.grey[200],
        child: const Center(
            child: Icon(Icons.image_not_supported, size: 64)),
      );
    }

    return SizedBox(
      width: screenWidth,
      height: maxHeight,
      child: Stack(
        children: [
          imageWidget,
          // BoundingBoxPainter positioned exactly over the rendered image area
          Positioned(
            left: offsetX,
            top: offsetY,
            width: renderW,
            height: renderH,
            child: CustomPaint(
              painter: BoundingBoxPainter(
                pods: pods,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-pod detail card ──────────────────────────────────────────────────────

class _PodDetailCard extends StatelessWidget {
  final DetectedPod pod;
  final int podNumber;

  const _PodDetailCard({required this.pod, required this.podNumber});

  @override
  Widget build(BuildContext context) {
    final ks = context.watch<LanguageProvider>().knowledgeService;
    final diag = pod.diagnosis;
    final color = AppConstants.colorForDiagnosis(diag.className);
    final isDiseased = diag.className != 'healthy';
    // Disease names always red for visibility; healthy stays green
    final nameColor = isDiseased ? Colors.red[700]! : color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row
          Container(
            color: color.withValues(alpha: 0.08),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Crop thumbnail or colored circle
                if (pod.cropBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      pod.cropBytes!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(Icons.spa, color: color),
                  ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Pod $podNumber',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (diag.isUncertain) ...[
                            const Icon(Icons.warning_amber,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              ks.sectionTitle('lowConfidenceTip'),
                              style: TextStyle(fontSize: 10, color: Colors.amber[700]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        DiagnosisCard.translatedDiagnosisName(diag.className, ks),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: nameColor,
                        ),
                      ),
                      Text(
                        '${(diag.confidence * 100).toStringAsFixed(1)}% ${ks.sectionTitle('confidence')}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Alternative diagnosis notice
          if (diag.hasAlternative)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.amber[50],
              child: Text(
                '${DiagnosisCard.translatedDiagnosisName(diag.alternative!.className, ks)} '
                '(${(diag.alternative!.confidence * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(
                    fontSize: 12, color: Colors.amber),
              ),
            ),

          // Treatment section
          _TreatmentSection(diagnosis: diag.className),
        ],
      ),
    );
  }
}

// ── Treatment recommendations ────────────────────────────────────────────────

class _TreatmentSection extends StatelessWidget {
  final String diagnosis;

  const _TreatmentSection({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final ks = lang.knowledgeService;
    final currentLang = lang.language;

    final info = getPodTreatment(diagnosis, currentLang) ??
        getLeafTreatment(diagnosis, currentLang);
    if (info == null) return const SizedBox.shrink();

    final severity = info['severity'] as String;
    final recommendations = info['recommendations'] as List;
    final color = AppConstants.colorForDiagnosis(diagnosis);
    final isNone = severity == 'none' || severity == 'aucune' ||
        severity == 'ninguna' || severity == 'hwee';

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(
        ks.sectionTitle('treatmentTitle'),
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: diagnosis != 'healthy',
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isNone) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${ks.sectionTitle('severityLabel')}: ${severity[0].toUpperCase()}${severity.substring(1)}',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              ...recommendations.map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
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
          ),
        ),
      ],
    );
  }
}
