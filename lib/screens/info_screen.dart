import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/treatment_data.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Information')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // How to use
          Text(
            'How to Use',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const _InstructionStep(
            number: '1',
            text: 'Tap "Take Photo" or "Pick from Gallery" to scan a cocoa leaf.',
          ),
          const _InstructionStep(
            number: '2',
            text: 'CocoaGuard analyses the image on-device — no internet needed.',
          ),
          const _InstructionStep(
            number: '3',
            text: 'Review the diagnosis, confidence score, and treatment recommendations.',
          ),
          const _InstructionStep(
            number: '4',
            text: 'Save results to track your scans over time.',
          ),

          const Divider(height: 32),

          // Disease guide
          Text(
            'Leaf Disease Guide',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _DiseaseInfoCard(
            name: 'Anthracnose (Black Pod)',
            diagnosis: 'anthracnose',
            description:
                'A fungal disease caused by Colletotrichum gloeosporioides. '
                'Infected pods develop dark brown to black lesions that spread '
                'rapidly, especially during wet seasons. Can cause up to 30–40% '
                'crop loss if untreated.',
            recommendations:
                List<String>.from(leafTreatments['anthracnose']!['recommendations']),
          ),

          _DiseaseInfoCard(
            name: 'Cocoa Swollen Shoot Virus Disease (CSSVD)',
            diagnosis: 'cssvd',
            description:
                'A severe viral disease transmitted by mealybugs. Causes swelling '
                'of shoots, root tips, and pods. Infected trees show reduced yield '
                'and eventually die. There is no cure — infected trees must be removed.',
            recommendations:
                List<String>.from(leafTreatments['cssvd']!['recommendations']),
          ),

          _DiseaseInfoCard(
            name: 'Healthy Leaf',
            diagnosis: 'healthy',
            description:
                'No signs of disease detected. Healthy cocoa leaves should have a '
                'uniform green color with no spots, lesions, or abnormal growth.',
            recommendations:
                List<String>.from(leafTreatments['healthy']!['recommendations']),
          ),

          const Divider(height: 32),

          // About
          Text(
            'About CocoaGuard',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'CocoaGuard uses an EfficientNetB3 deep learning model running '
            'entirely on your device — no internet connection required for '
            'disease detection. The leaf model achieves 92.13% accuracy on '
            'Ghanaian cocoa leaf images.',
          ),
          const SizedBox(height: 8),
          const Text(
            'This app is a decision-support tool. Always consult a local '
            'COCOBOD extension officer for confirmation and official guidance.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.brown[100],
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _DiseaseInfoCard extends StatelessWidget {
  final String name;
  final String diagnosis;
  final String description;
  final List<String> recommendations;

  const _DiseaseInfoCard({
    required this.name,
    required this.diagnosis,
    required this.description,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.colorForDiagnosis(diagnosis);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            const Text(
              'Recommendations:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            ...recommendations.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('  •  ', style: TextStyle(color: color)),
                    Expanded(
                      child: Text(r, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
