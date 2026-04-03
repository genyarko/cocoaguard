import 'package:flutter_test/flutter_test.dart';
import 'package:cocoaguard/models/task_type.dart';
import 'package:cocoaguard/services/task_router_service.dart';

void main() {
  group('TaskRouterService.classify', () {
    // ── Emergency detection ──────────────────────────────────────────────
    group('emergency', () {
      test('strong emergency keyword triggers emergency', () {
        expect(TaskRouterService.classify('emergency help my tree is dying'),
            TaskType.emergency);
      });

      test('poisoning is emergency', () {
        expect(TaskRouterService.classify('I think pesticide poisoning'),
            TaskType.emergency);
      });

      test('chemical exposure is emergency', () {
        expect(TaskRouterService.classify('chemical exposure on my skin'),
            TaskType.emergency);
      });

      test('two mild keywords score >= 2 → emergency', () {
        // 'help' (+1) + 'severe' (+1) = 2
        expect(TaskRouterService.classify('help this is severe'),
            TaskType.emergency);
      });

      test('single mild keyword alone is not emergency', () {
        // 'help' alone scores 1 < 2
        expect(
            TaskRouterService.classify('help'), isNot(TaskType.emergency));
      });

      test('"my tree is dying help" → emergency', () {
        expect(TaskRouterService.classify('my tree is dying help'),
            TaskType.emergency);
      });

      test('outbreak triggers emergency', () {
        expect(TaskRouterService.classify('there is a disease outbreak'),
            TaskType.emergency);
      });
    });

    // ── Question detection ───────────────────────────────────────────────
    group('question', () {
      test('starts with "what " → question', () {
        expect(TaskRouterService.classify('what causes black pod'),
            TaskType.question);
      });

      test('starts with "how " → question', () {
        expect(TaskRouterService.classify('how do I treat anthracnose'),
            TaskType.question);
      });

      test('starts with "why " → question', () {
        expect(TaskRouterService.classify('why do my pods turn black'),
            TaskType.question);
      });

      test('contains "treatment" keyword → question', () {
        expect(
            TaskRouterService.classify('anthracnose treatment options'),
            TaskType.question);
      });

      test('contains "best practice" → question', () {
        expect(TaskRouterService.classify('best practice for pruning'),
            TaskType.question);
      });

      test('"tell me about cssvd" → question', () {
        expect(TaskRouterService.classify('tell me about cssvd'),
            TaskType.question);
      });

      test('any text > 3 chars defaults to question', () {
        expect(TaskRouterService.classify('cocoa pods'),
            TaskType.question);
      });
    });

    // ── Unknown / empty ──────────────────────────────────────────────────
    group('unknown', () {
      test('empty string → unknown', () {
        expect(TaskRouterService.classify(''), TaskType.unknown);
      });

      test('whitespace only → unknown', () {
        expect(TaskRouterService.classify('   '), TaskType.unknown);
      });

      test('very short text (≤3 chars) → unknown', () {
        expect(TaskRouterService.classify('hi'), TaskType.unknown);
      });
    });

    // ── Case insensitivity ───────────────────────────────────────────────
    test('classification is case insensitive', () {
      expect(TaskRouterService.classify('WHAT causes BLACK POD'),
          TaskType.question);
      expect(TaskRouterService.classify('EMERGENCY MY TREE IS DYING'),
          TaskType.emergency);
    });
  });
}
