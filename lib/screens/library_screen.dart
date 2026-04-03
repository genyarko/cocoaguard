import 'package:flutter/material.dart';

import '../services/knowledge_service.dart';
import '../utils/constants.dart';

/// Browsable offline library of all diseases, farming tips, and COCOBOD
/// resources. Works 100% without internet.
class LibraryScreen extends StatelessWidget {
  final KnowledgeService knowledgeService;

  const LibraryScreen({super.key, required this.knowledgeService});

  @override
  Widget build(BuildContext context) {
    if (!knowledgeService.isLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Offline Library')),
        body: const Center(child: Text('Knowledge base is loading...')),
      );
    }

    final diseases =
        knowledgeService.diseases.where((d) => d.id != 'healthy').toList();
    final tips = knowledgeService.generalTips;
    final cocobod = knowledgeService.cocobod;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Library'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'All content available offline — no internet needed',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Disease guide ──────────────────────────────────────────
          _SectionHeader(
            icon: Icons.bug_report,
            title: 'Disease Guide',
            subtitle: '${diseases.length} diseases',
          ),
          const SizedBox(height: 8),
          ...diseases.map((d) => _DiseaseCard(disease: d)),

          const SizedBox(height: 24),

          // ── Farming best practices ─────────────────────────────────
          _SectionHeader(
            icon: Icons.agriculture,
            title: 'Farming Best Practices',
            subtitle: '${tips.length} tips',
          ),
          const SizedBox(height: 8),
          ...tips.map((t) => _TipCard(tip: t)),

          // ── COCOBOD resources ──────────────────────────────────────
          if (cocobod != null) ...[
            const SizedBox(height: 24),
            const _SectionHeader(
              icon: Icons.account_balance,
              title: 'COCOBOD Resources',
              subtitle: 'Ghana Cocoa Board',
            ),
            const SizedBox(height: 8),
            _CocobodCard(info: cocobod),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: '$title — $subtitle',
      child: Row(
        children: [
          Icon(icon, color: Colors.brown[700], size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.brown[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.brown[600]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Disease card ─────────────────────────────────────────────────────────────

class _DiseaseCard extends StatelessWidget {
  final DiseaseEntry disease;

  const _DiseaseCard({required this.disease});

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.colorForDiagnosis(disease.id);
    final isLeaf = disease.scanType == 'leaf';

    return Semantics(
      label: '${disease.name}, severity ${disease.severity}, ${isLeaf ? "leaf" : "pod"} disease',
      child: Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isLeaf ? Icons.eco : Icons.spa,
            color: color,
            size: 18,
          ),
        ),
        title: Text(
          disease.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        subtitle: Row(
          children: [
            _SeverityChip(severity: disease.severity, color: color),
            const SizedBox(width: 6),
            Text(
              isLeaf ? 'Leaf' : 'Pod',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disease.description,
                  style: const TextStyle(height: 1.5),
                ),

                if (disease.symptoms.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SubSection(
                    title: 'Symptoms',
                    icon: Icons.visibility,
                    items: disease.symptoms,
                    color: color,
                  ),
                ],

                if (disease.causes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SubSection(
                    title: 'Causes',
                    icon: Icons.help_outline,
                    items: disease.causes,
                    color: color,
                  ),
                ],

                if (disease.treatments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SubSection(
                    title: 'Treatment',
                    icon: Icons.medical_services_outlined,
                    items: disease.treatments,
                    color: color,
                  ),
                ],

                if (disease.prevention.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SubSection(
                    title: 'Prevention',
                    icon: Icons.shield_outlined,
                    items: disease.prevention,
                    color: color,
                  ),
                ],

                if (disease.faq.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Frequently Asked',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.brown[800],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...disease.faq.map((faq) => _FaqTile(faq: faq)),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ── Sub-section (symptoms, causes, etc.) ─────────────────────────────────────

class _SubSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Color color;

  const _SubSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.brown[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: color)),
                Expanded(
                  child: Text(item, style: const TextStyle(fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── FAQ tile ─────────────────────────────────────────────────────────────────

class _FaqTile extends StatelessWidget {
  final FaqEntry faq;

  const _FaqTile({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'FAQ: ${faq.question}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.brown[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            faq.question,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          children: [
            Text(faq.answer, style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ── Severity chip ────────────────────────────────────────────────────────────

class _SeverityChip extends StatelessWidget {
  final String severity;
  final Color color;

  const _SeverityChip({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    if (severity == 'none') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        severity,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Farming tip card ─────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final GeneralTip tip;

  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Farming tip: ${tip.topic}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.green.withValues(alpha: 0.15)),
        ),
        child: ExpansionTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.green[50],
            child: Icon(Icons.lightbulb_outline, color: Colors.green[700], size: 16),
          ),
          title: Text(
            tip.topic,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(tip.answer, style: const TextStyle(height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── COCOBOD resources card ───────────────────────────────────────────────────

class _CocobodCard extends StatelessWidget {
  final CocobodInfo info;

  const _CocobodCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.description,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 14),

            Text(
              'When to Contact COCOBOD',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 4),
            ...info.whenToContact.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child:
                          Text(item, style: const TextStyle(fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Services Available',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 4),
            ...info.services.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: Colors.green[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child:
                          Text(item, style: const TextStyle(fontSize: 13, height: 1.4)),
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
