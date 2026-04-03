import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Displays emergency protocols loaded from assets/data/emergency_protocols.json.
///
/// When [initialQuery] is provided (from the task router), protocols are sorted
/// by keyword relevance so the most applicable one appears first and is auto-
/// expanded.
class EmergencyScreen extends StatefulWidget {
  final String? initialQuery;

  const EmergencyScreen({super.key, this.initialQuery});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final json =
        await rootBundle.loadString('assets/data/emergency_protocols.json');
    setState(() {
      _data = jsonDecode(json) as Map<String, dynamic>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Protocols'),
        backgroundColor: Colors.red[50],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Could not load protocols.'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final protocols = List<Map<String, dynamic>>.from(_data!['protocols']);
    final contacts =
        _data!['general_emergency_contacts'] as Map<String, dynamic>;

    // Sort by relevance if a query was provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      protocols.sort((a, b) {
        final scoreA = _relevance(a, widget.initialQuery!);
        final scoreB = _relevance(b, widget.initialQuery!);
        return scoreB.compareTo(scoreA);
      });
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Warning banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red[700], size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'These are general guidelines. In a medical emergency, '
                  'seek professional help immediately.',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (widget.initialQuery != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing results for: "${widget.initialQuery}"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Protocol cards
        ...protocols.asMap().entries.map((entry) {
          final isFirst = entry.key == 0 && widget.initialQuery != null;
          return _ProtocolCard(
            protocol: entry.value,
            initiallyExpanded: isFirst,
          );
        }),

        const SizedBox(height: 24),

        // General contacts
        Text(
          'General Emergency Resources',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contacts['note'] as String,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 12),
                ...List<String>.from(contacts['resources']).map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.arrow_right,
                            size: 18, color: Colors.brown[400]),
                        const SizedBox(width: 4),
                        Expanded(child: Text(r, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  int _relevance(Map<String, dynamic> protocol, String query) {
    final keywords = List<String>.from(protocol['trigger_keywords']);
    final lower = query.toLowerCase();
    int score = 0;
    for (final kw in keywords) {
      if (lower.contains(kw.toLowerCase())) score++;
    }
    return score;
  }
}

// ── Protocol card ────────────────────────────────────────────────────────────

class _ProtocolCard extends StatelessWidget {
  final Map<String, dynamic> protocol;
  final bool initiallyExpanded;

  const _ProtocolCard({
    required this.protocol,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final severity = protocol['severity'] as String;
    final title = protocol['title'] as String;
    final description = protocol['description'] as String;
    final immediateActions =
        List<String>.from(protocol['immediate_actions']);
    final shortTermActions =
        List<String>.from(protocol['short_term_actions']);
    final contact = protocol['contact'] as Map<String, dynamic>;

    final severityColor = _severityColor(severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _SeverityBadge(severity: severity, color: severityColor),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Immediate actions
                _ActionSection(
                  icon: Icons.flash_on,
                  title: 'Immediate Actions',
                  color: Colors.red[700]!,
                  actions: immediateActions,
                ),
                const SizedBox(height: 16),

                // Short-term actions
                _ActionSection(
                  icon: Icons.checklist,
                  title: 'Short-Term Actions',
                  color: Colors.orange[700]!,
                  actions: shortTermActions,
                ),
                const SizedBox(height: 16),

                // Contact info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone, size: 18, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Contact',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _contactLine('Who', contact['who'] as String),
                      _contactLine('When', contact['when'] as String),
                      _contactLine(
                          'What to say', contact['what_to_say'] as String),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red[700]!;
      case 'medical':
        return Colors.purple[700]!;
      case 'high':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}

// ── Severity badge ───────────────────────────────────────────────────────────

class _SeverityBadge extends StatelessWidget {
  final String severity;
  final Color color;

  const _SeverityBadge({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Action list section ──────────────────────────────────────────────────────

class _ActionSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> actions;

  const _ActionSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...actions.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${e.key + 1}.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(e.value, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
