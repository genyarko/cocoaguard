import '../models/task_type.dart';

/// Rule-based input classifier that routes user text to the appropriate
/// pipeline (emergency, question, or unknown).
///
/// Uses a weighted keyword scoring system:
///   - Strong emergency signals score +2 (poisoning, outbreak, injury ...)
///   - Mild emergency signals score +1 (help, severe, spreading ...)
///   - A total score >= 2 triggers the emergency path.
///   - Otherwise, question patterns are checked.
///   - Any remaining text longer than 3 characters defaults to question.
class TaskRouterService {
  TaskRouterService._();

  // ── Emergency keywords ────────────────────────────────────────────────────

  static const _strongEmergency = [
    'emergency',
    'urgent',
    'dying',
    'outbreak',
    'poisoning',
    'pesticide',
    'chemical exposure',
    'injury',
    'bleeding',
    'swallowed',
    'inhaled',
    'eyes burn',
    'skin burn',
    'losing everything',
    'nothing left',
    'total loss',
    'entire farm',
    'all trees',
  ];

  static const _mildEmergency = [
    'help',
    'severe',
    'serious',
    'bad',
    'spreading',
    'disaster',
    'losing',
    'lost',
    'chemical',
    'quarantine',
    'swollen shoot',
    'cssvd',
  ];

  // ── Question patterns ─────────────────────────────────────────────────────

  static const _questionStarts = [
    'what ',
    'why ',
    'how ',
    'when ',
    'where ',
    'which ',
    'who ',
    'is ',
    'are ',
    'can ',
    'should ',
    'does ',
    'do ',
    'tell me',
    'explain',
    'describe',
  ];

  static const _questionKeywords = [
    'causes',
    'treatment',
    'prevent',
    'recommend',
    'best practice',
    'symptoms',
    'difference between',
    'how to',
    'what is',
    'fungicide',
    'fertilizer',
  ];

  // ── Classify ──────────────────────────────────────────────────────────────

  static TaskType classify(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.isEmpty) return TaskType.unknown;

    // Score emergency signals
    int score = 0;
    for (final kw in _strongEmergency) {
      if (lower.contains(kw)) score += 2;
    }
    for (final kw in _mildEmergency) {
      if (lower.contains(kw)) score += 1;
    }
    if (score >= 2) return TaskType.emergency;

    // Check question patterns
    for (final prefix in _questionStarts) {
      if (lower.startsWith(prefix)) return TaskType.question;
    }
    for (final kw in _questionKeywords) {
      if (lower.contains(kw)) return TaskType.question;
    }

    // Any non-trivial text is treated as a question
    if (lower.length > 3) return TaskType.question;

    return TaskType.unknown;
  }
}
