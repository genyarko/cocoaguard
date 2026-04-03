import 'package:flutter/material.dart';

/// Placeholder screen for Gemma 4 Q&A (Phase 4).
///
/// Acknowledges the user's question and signals that the intelligent
/// farming assistant is coming. This keeps the task-router wiring
/// functional so that routing can be demoed before the full Q&A is built.
class QaPlaceholderScreen extends StatelessWidget {
  final String? question;

  const QaPlaceholderScreen({super.key, this.question});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask the Expert')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.smart_toy_outlined,
                  size: 72, color: Colors.green[300]),
              const SizedBox(height: 24),

              if (question != null && question!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.brown[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your question:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                'Gemma 4 Farming Expert',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'An intelligent farming assistant powered by Gemma 4 '
                'is coming soon. It will answer questions about cocoa '
                'diseases, treatments, and farming best practices — '
                'with offline fallback.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Suggestions
              Text(
                'In the meantime, try:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              _SuggestionRow(
                  icon: Icons.camera_alt,
                  text: 'Scan a leaf or pod for instant diagnosis'),
              _SuggestionRow(
                  icon: Icons.warning_amber,
                  text: 'Use Emergency Help for urgent farm issues'),
              _SuggestionRow(
                  icon: Icons.info_outline,
                  text: 'Check the Info tab for disease guides'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SuggestionRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
