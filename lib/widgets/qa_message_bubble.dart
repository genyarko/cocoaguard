import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/conversation.dart';

/// Displays a single Q&A exchange: user question on the right, AI answer on
/// the left, with a source tag ("Powered by Gemma 4" or "Offline answer").
class QaMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;

  const QaMessageBubble({
    super.key,
    required this.message,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm().format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── User question (right-aligned) ─────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                message.question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // ── AI answer (left-aligned) ──────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.brown[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: Colors.brown.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scan context badge (if present)
                  if (message.scanContext != null &&
                      message.scanContext!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.linked_camera,
                              size: 12, color: Colors.orange[800]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              message.scanContext!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Answer text
                  SelectableText(
                    message.answer,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.brown[900],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Footer: source tag + time
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SourceTag(source: message.source),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTag extends StatelessWidget {
  final String source;

  const _SourceTag({required this.source});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    switch (source) {
      case 'gemma4':
        color = Colors.green[700]!;
        label = 'Powered by Gemma 4';
        icon = Icons.auto_awesome;
      case 'cached':
        color = Colors.blue[600]!;
        label = 'Cached answer';
        icon = Icons.cached;
      default:
        color = Colors.grey[600]!;
        label = 'Offline answer';
        icon = Icons.cloud_off;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
