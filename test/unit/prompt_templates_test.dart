import 'package:flutter_test/flutter_test.dart';
import 'package:cocoaguard/utils/prompt_templates.dart';

void main() {
  group('PromptTemplates', () {
    test('systemPrompt mentions cocoa and Ghana', () {
      expect(PromptTemplates.systemPrompt.toLowerCase(), contains('cocoa'));
      expect(PromptTemplates.systemPrompt.toLowerCase(), contains('ghana'));
    });

    test('systemPrompt mentions COCOBOD', () {
      expect(PromptTemplates.systemPrompt, contains('COCOBOD'));
    });

    group('question()', () {
      test('includes system prompt', () {
        final prompt = PromptTemplates.question('What is black pod?');
        expect(prompt, contains(PromptTemplates.systemPrompt));
      });

      test('includes user question', () {
        final prompt = PromptTemplates.question('What is black pod?');
        expect(prompt, contains('What is black pod?'));
      });

      test('includes instruction to be brief', () {
        final prompt = PromptTemplates.question('test');
        expect(prompt.toLowerCase(), contains('brief'));
      });
    });

    group('questionAfterScan()', () {
      test('includes disease name and confidence', () {
        final prompt = PromptTemplates.questionAfterScan(
          userQuestion: 'How do I treat this?',
          disease: 'phytophthora',
          confidence: 87.5,
          scanType: 'pod',
        );
        expect(prompt, contains('phytophthora'));
        expect(prompt, contains('87.5%'));
      });

      test('includes scan type', () {
        final prompt = PromptTemplates.questionAfterScan(
          userQuestion: 'test',
          disease: 'anthracnose',
          confidence: 92.0,
          scanType: 'leaf',
        );
        expect(prompt, contains('leaf'));
      });

      test('includes user question', () {
        final prompt = PromptTemplates.questionAfterScan(
          userQuestion: 'Should I remove the tree?',
          disease: 'cssvd',
          confidence: 80.0,
          scanType: 'leaf',
        );
        expect(prompt, contains('Should I remove the tree?'));
      });

      test('mentions low confidence warning threshold', () {
        final prompt = PromptTemplates.questionAfterScan(
          userQuestion: 'test',
          disease: 'test',
          confidence: 50.0,
          scanType: 'pod',
        );
        expect(prompt.toLowerCase(), contains('70%'));
      });
    });

    test('suggestedQuestions is not empty', () {
      expect(PromptTemplates.suggestedQuestions, isNotEmpty);
      expect(PromptTemplates.suggestedQuestions.length, greaterThanOrEqualTo(4));
    });

    test('all suggested questions are non-empty strings', () {
      for (final q in PromptTemplates.suggestedQuestions) {
        expect(q.trim(), isNotEmpty);
      }
    });
  });
}
