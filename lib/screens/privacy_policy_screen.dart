import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.onyx,
        foregroundColor: AppColors.chartreuse,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _PolicySection(
            title: 'Overview',
            body:
                'CocoaGuard is designed with your privacy in mind. The app runs '
                'entirely on your device — AI models, disease detection, and the '
                'offline knowledge base all operate locally without sending your '
                'photos or farm data to any server.',
          ),
          _PolicySection(
            title: 'Data We Collect',
            body:
                'CocoaGuard does not collect any personal data. The following '
                'information stays on your device only:\n\n'
                '• Photos you take or select for scanning\n'
                '• Scan results and history\n'
                '• Q&A chat history\n'
                '• App settings and preferences\n\n'
                'None of this data is transmitted, sold, or shared with third parties.',
          ),
          _PolicySection(
            title: 'Camera & Storage Permissions',
            body:
                'CocoaGuard requests camera and storage permissions solely to '
                'capture and read images for disease detection. Images are stored '
                'locally in your device\'s app storage and are deleted when you '
                'clear your scan history in Settings.',
          ),
          _PolicySection(
            title: 'Internet & AI (Gemma 4)',
            body:
                'When an internet connection is available, CocoaGuard may send '
                'your text questions to the Gemma 4 cloud API to generate answers. '
                'Photos and scan results are never sent over the internet.\n\n'
                'When offline, all questions are answered using the on-device '
                'knowledge base — no data leaves your device.',
          ),
          _PolicySection(
            title: 'Third-Party Services',
            body:
                'The only external service used is the Gemma 4 API (Google) for '
                'text-based Q&A responses. No analytics, advertising SDKs, or '
                'tracking libraries are included in this app.',
          ),
          _PolicySection(
            title: 'Data Retention & Deletion',
            body:
                'You are in full control of your data. You can delete all scan '
                'history and chat history at any time from the Settings screen. '
                'Uninstalling the app removes all locally stored data.',
          ),
          _PolicySection(
            title: 'Children\'s Privacy',
            body:
                'CocoaGuard does not knowingly collect information from children '
                'under 13. The app is intended for use by cocoa farmers and '
                'agricultural professionals.',
          ),
          _PolicySection(
            title: 'Changes to This Policy',
            body:
                'This privacy policy may be updated with future app versions. '
                'Significant changes will be noted in the app update release notes.',
          ),
          _PolicySection(
            title: 'Contact',
            body:
                'For privacy questions or concerns, please open an issue on the '
                'GitHub repository: github.com/genyarko/cocoaguard',
          ),
          SizedBox(height: 8),
          Text(
            'Last updated: April 2026',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.toffeeBrown,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
