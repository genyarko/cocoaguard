/// Domain-specific prompt templates for the Gemma 4 farming Q&A.
///
/// Keeps all prompt engineering in one place so it's easy to tune and
/// easy for hackathon judges to review.
class PromptTemplates {
  PromptTemplates._();

  static const systemPrompt = '''
You are an expert agricultural advisor for cocoa farmers in Ghana.
Your role is to:
1. Explain cocoa diseases (causes, symptoms, how they spread)
2. Recommend treatments based on disease type and severity
3. Provide emergency guidance (when to call COCOBOD, quarantine steps)
4. Share farming best practices (seasonal care, pest prevention, shade management)

Rules for every answer:
- Keep it brief: 2-4 sentences for quick reference.
- Be actionable: give specific treatment steps the farmer can follow today.
- Ground answers in local context: mention COCOBOD, local practices, and affordable inputs.
- Always recommend professional confirmation for any diagnosis.
- If you are not sure, say so — do not guess.
- Use simple English that is easy to understand for non-native speakers.''';

  /// Build a plain question prompt (no scan context).
  static String question(String userQuestion) {
    return '''$systemPrompt

Farmer's question: $userQuestion

Remember: Keep your answer brief and actionable for a farmer with limited internet access.''';
  }

  /// Build a context-aware prompt when the user just scanned a diseased pod/leaf.
  ///
  /// [disease] — the classification label (e.g. "phytophthora")
  /// [confidence] — the model's confidence as a percentage (e.g. 87.2)
  /// [scanType] — 'leaf' or 'pod'
  static String questionAfterScan({
    required String userQuestion,
    required String disease,
    required double confidence,
    required String scanType,
  }) {
    return '''$systemPrompt

Context: The farmer just scanned a cocoa $scanType using an on-device AI model.
Detection result: $disease (${confidence.toStringAsFixed(1)}% confidence).

Farmer's follow-up question: $userQuestion

Use the scan result as context when answering. If the confidence is below 70%, mention that the detection is uncertain and a professional should verify.
Keep your answer brief and actionable.''';
  }

  /// Suggested questions to display on the Q&A screen.
  static const suggestedQuestions = [
    'What causes black pod disease?',
    'How do I treat anthracnose?',
    'When should I call COCOBOD?',
    'Best practices for cocoa shade management?',
    'How to prevent CSSVD from spreading?',
    'What fungicide should I use for pod rot?',
  ];
}
