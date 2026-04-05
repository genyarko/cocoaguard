import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/scan_record.dart';
import '../providers/language_provider.dart';
import '../utils/constants.dart';
import 'diagnosis_card.dart';

class ScanCard extends StatelessWidget {
  final ScanRecord record;
  final VoidCallback? onTap;

  const ScanCard({
    super.key,
    required this.record,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ks = context.watch<LanguageProvider>().knowledgeService;
    final color = AppConstants.colorForDiagnosis(record.diagnosis);
    final dateStr = DateFormat('MMM d, yyyy – h:mm a').format(record.scannedAt);
    final confidence = (record.confidence * 100).toStringAsFixed(1);
    final imageFile = File(record.imagePath);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: imageFile.existsSync()
                  ? Image.file(imageFile, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DiagnosisCard.translatedDiagnosisName(record.diagnosis, ks),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: color,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            record.scanType.toUpperCase(),
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$confidence% ${ks.sectionTitle('confidence')}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
