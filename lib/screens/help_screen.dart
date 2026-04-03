import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Help & Guide'),
          backgroundColor: AppColors.onyx,
          foregroundColor: AppColors.chartreuse,
          bottom: TabBar(
            labelColor: AppColors.chartreuse,
            unselectedLabelColor: AppColors.mediumGray,
            indicatorColor: AppColors.chartreuse,
            tabs: const [
              Tab(text: 'Getting Started'),
              Tab(text: 'Scanning'),
              Tab(text: 'FAQs'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GettingStartedTab(),
            _ScanningTab(),
            _FaqTab(),
          ],
        ),
      ),
    );
  }
}

// ── Getting Started ───────────────────────────────────────────────────────────

class _GettingStartedTab extends StatelessWidget {
  const _GettingStartedTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _HelpCard(
          icon: Icons.eco,
          iconColor: AppColors.chartreuse,
          title: 'What is CocoaGuard?',
          body:
              'CocoaGuard helps cocoa farmers in Ghana detect plant diseases '
              'using AI. Point your camera at a leaf or pod and get an instant '
              'diagnosis with treatment recommendations — even without internet.',
        ),
        _HelpCard(
          icon: Icons.camera_alt,
          iconColor: AppColors.chartreuse,
          title: 'How to Scan',
          body:
              '1. Tap the Leaf button to scan a cocoa leaf for diseases like '
              'Anthracnose or CSSVD.\n\n'
              '2. Tap the Pod button to detect diseases on cocoa pods — the app '
              'finds each pod in the photo automatically.\n\n'
              '3. Tap the center camera button for a quick pod scan using the '
              'live camera viewfinder.',
        ),
        _HelpCard(
          icon: Icons.chat_bubble_outline,
          iconColor: AppColors.chartreuse,
          title: 'Ask Questions',
          body:
              'Use the Q&A feature to ask farming questions in plain language. '
              'For example: "How do I treat black pod rot?" or "When should I '
              'harvest my pods?"\n\n'
              'After a scan, tap "Ask about this disease" for context-specific '
              'advice powered by Gemma 4 AI.',
        ),
        _HelpCard(
          icon: Icons.signal_wifi_off,
          iconColor: AppColors.chartreuse,
          title: 'Works Offline',
          body:
              'All AI scanning works without internet. Disease detection, leaf '
              'classification, and the knowledge library are fully on-device.\n\n'
              'Q&A answers from Gemma 4 require internet, but previous answers '
              'are cached and the offline knowledge base answers common questions '
              'without any connection.',
        ),
        _HelpCard(
          icon: Icons.local_library_outlined,
          iconColor: AppColors.chartreuse,
          title: 'Offline Library',
          body:
              'The Library tab contains detailed information on all detectable '
              'diseases — symptoms, causes, treatments, prevention, and FAQs. '
              'Browse it anytime without internet.',
        ),
      ],
    );
  }
}

// ── Scanning Tips ─────────────────────────────────────────────────────────────

class _ScanningTab extends StatelessWidget {
  const _ScanningTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionHeader(title: 'For Best Results'),
        const _TipRow(
          icon: Icons.wb_sunny_outlined,
          text: 'Use natural daylight. Avoid harsh direct sunlight or deep shade.',
        ),
        const _TipRow(
          icon: Icons.center_focus_strong,
          text: 'Tap the screen to focus before capturing. Hold the phone steady.',
        ),
        const _TipRow(
          icon: Icons.straighten,
          text:
              'Hold 20–40 cm from the leaf or pod. Fill most of the frame with the subject.',
        ),
        const _TipRow(
          icon: Icons.flip_camera_android,
          text:
              'For pod scans, include 1–4 pods per photo. Ensure pods are clearly visible and not heavily overlapping.',
        ),
        const _TipRow(
          icon: Icons.image_not_supported_outlined,
          text:
              'Avoid blurry, overexposed, or very dark images. The app will warn you if quality is too low.',
        ),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Understanding Confidence'),
        _InfoBox(
          color: Colors.green[700]!,
          label: 'High (≥ 80%)',
          description: 'Reliable result. Proceed with treatment recommendations.',
        ),
        _InfoBox(
          color: Colors.orange[700]!,
          label: 'Medium (55–79%)',
          description:
              'Reasonable result. Consider retaking with a clearer image to confirm.',
        ),
        _InfoBox(
          color: Colors.red[700]!,
          label: 'Low (< 55%)',
          description:
              'Uncertain. Retake with better lighting and focus. Consult a COCOBOD officer if unsure.',
        ),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Detectable Diseases'),
        _DiseaseChip(label: 'Leaf — Anthracnose', color: Color(0xFFFF9500)),
        _DiseaseChip(label: 'Leaf — CSSVD', color: Color(0xFF8B0000)),
        _DiseaseChip(label: 'Pod — Phytophthora (Black Pod)', color: Color(0xFF555555)),
        _DiseaseChip(label: 'Pod — Carmenta (Pod Borer)', color: Color(0xFFDC143C)),
        _DiseaseChip(label: 'Pod — Moniliasis (Frosty Pod)', color: Color(0xFF8B4513)),
        _DiseaseChip(label: 'Pod — Witches\' Broom', color: Color(0xFF654321)),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── FAQs ──────────────────────────────────────────────────────────────────────

class _FaqTab extends StatelessWidget {
  const _FaqTab();

  static const _faqs = [
    _FaqItem(
      question: 'Why is my scan result uncertain?',
      answer:
          'Uncertain results (< 55% confidence) are caused by poor image quality — '
          'blurriness, bad lighting, or the wrong subject filling the frame. '
          'Retake the photo in good natural light, tap to focus, and ensure the '
          'leaf or pod fills most of the camera view.',
    ),
    _FaqItem(
      question: 'Can I scan both leaves and pods?',
      answer:
          'Yes. Use the Leaf button for leaf scans (detects Anthracnose and CSSVD) '
          'and the Pod button or center camera for pod scans (detects Phytophthora, '
          'Carmenta, Moniliasis, and Witches\' Broom).',
    ),
    _FaqItem(
      question: 'Does the app work without internet?',
      answer:
          'Yes. All scanning (leaf and pod classification) works fully offline. '
          'The knowledge library and disease information are also available offline. '
          'Only Gemma 4 Q&A requires internet — but the app falls back to cached '
          'answers and the local knowledge base when offline.',
    ),
    _FaqItem(
      question: 'How do I save a scan result?',
      answer:
          'After a scan, tap "Save Result" on the results screen. Saved scans '
          'appear in the History tab and can be viewed anytime.',
    ),
    _FaqItem(
      question: 'How do I view my past scans?',
      answer:
          'Tap the History button in the bottom navigation bar. Each saved scan '
          'shows the date, diagnosis, and confidence score. Tap any entry to view '
          'full details and treatment recommendations.',
    ),
    _FaqItem(
      question: 'What do I do after a disease is detected?',
      answer:
          'Review the treatment recommendations on the results screen, then tap '
          '"Ask about this disease" to get personalised advice from Gemma 4. '
          'For severe diseases like CSSVD, contact your local COCOBOD extension '
          'officer immediately.',
    ),
    _FaqItem(
      question: 'How do I clear my data?',
      answer:
          'Go to Settings → Data Management. You can clear scan history or chat '
          'history separately. Cleared data cannot be recovered.',
    ),
    _FaqItem(
      question: 'Is my farm data shared with anyone?',
      answer:
          'No. All photos and scan results stay on your device. Only text questions '
          'sent to the Gemma 4 API travel over the internet — no images or personal '
          'information are ever transmitted. See the Privacy Policy for full details.',
    ),
    _FaqItem(
      question: 'How accurate is the disease detection?',
      answer:
          'The AI models were trained on cocoa leaf and pod disease datasets. '
          'Accuracy is highest with clear, well-lit, focused images. Always '
          'cross-check results with the treatment guidelines in the Library and '
          'consult a COCOBOD extension officer for critical decisions.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: _faqs
          .map((faq) => _FaqTile(question: faq.question, answer: faq.answer))
          .toList(),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _HelpCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: AppColors.lightGray,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(body,
                      style: const TextStyle(fontSize: 13, height: 1.55)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.toffeeBrown,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.chartreuse),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Color color;
  final String label;
  final String description;
  const _InfoBox(
      {required this.color, required this.label, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13),
                children: [
                  TextSpan(
                      text: '$label: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: color)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiseaseChip extends StatelessWidget {
  final String label;
  final Color color;
  const _DiseaseChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppColors.lightGray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding:
            const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(question,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        children: [
          Text(answer,
              style: const TextStyle(fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}
