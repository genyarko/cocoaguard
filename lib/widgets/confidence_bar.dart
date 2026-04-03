import 'package:flutter/material.dart';

class ConfidenceBar extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const ConfidenceBar({
    super.key,
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label[0].toUpperCase() + label.substring(1),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$percentage%',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
