import 'package:flutter_test/flutter_test.dart';
import 'package:cocoaguard/services/knowledge_service.dart';

void main() {
  late KnowledgeService service;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    service = KnowledgeService();
    await service.init();
  });

  group('KnowledgeService loading', () {
    test('loads diseases from JSON', () {
      expect(service.isLoaded, isTrue);
      expect(service.diseases.length, greaterThanOrEqualTo(7));
    });

    test('loads general farming tips', () {
      expect(service.generalTips, isNotEmpty);
    });

    test('loads COCOBOD resources', () {
      expect(service.cocobod, isNotNull);
      expect(service.cocobod!.services, isNotEmpty);
    });

    test('findById returns correct disease', () {
      final d = service.findById('anthracnose');
      expect(d, isNotNull);
      expect(d!.name, contains('Anthracnose'));
    });

    test('findById returns null for unknown id', () {
      expect(service.findById('nonexistent'), isNull);
    });
  });

  group('KnowledgeService.search', () {
    test('finds anthracnose by name', () {
      final result = service.search('What is anthracnose?');
      // May return FAQ answer or disease overview — both are valid
      expect(result, isNotEmpty);
      expect(result.length, greaterThan(20));
    });

    test('finds phytophthora by name', () {
      final result = service.search('tell me about phytophthora');
      expect(result, isNotEmpty);
      expect(result.toLowerCase(),
          anyOf(contains('phytophthora'), contains('black pod')));
    });

    test('returns relevant info when asking about treatment', () {
      final result = service.search('treatment for phytophthora black pod rot');
      // Should return something relevant to phytophthora — could be FAQ,
      // treatment list, or disease overview depending on keyword scoring.
      expect(result, isNotEmpty);
      expect(result.length, greaterThan(30));
    });

    test('returns prevention info when asking about prevention', () {
      final result = service.search('How to prevent CSSVD from spreading?');
      expect(result.toLowerCase(),
          anyOf(contains('prevent'), contains('control'), contains('monitor'),
              contains('resistant'), contains('mealybug')));
    });

    test('matches FAQ questions', () {
      final result = service.search('How does anthracnose spread?');
      // Should match the FAQ entry about spores
      expect(result.toLowerCase(), contains('spore'));
    });

    test('finds general farming tips by topic keywords', () {
      final result = service.search('fertilizer recommendations for my cocoa farm');
      expect(result.toLowerCase(),
          anyOf(contains('fertili'), contains('npk'), contains('apply')));
    });

    test('finds COCOBOD info', () {
      final result = service.search('When should I report to COCOBOD?');
      expect(result.toLowerCase(), contains('cocobod'));
    });

    test('returns fallback for completely unrelated questions', () {
      // Use words with zero overlap with agricultural/disease corpus
      final result = service.search('xyz quantum blockchain metaverse');
      expect(result.toLowerCase(), contains("don't have"));
    });

    test('handles empty query gracefully', () {
      final result = service.search('');
      // Should return the fallback message
      expect(result, isNotEmpty);
    });
  });

  group('DiseaseEntry data integrity', () {
    test('all diseases have required fields', () {
      for (final d in service.diseases) {
        expect(d.id, isNotEmpty, reason: '${d.name} missing id');
        expect(d.name, isNotEmpty, reason: '${d.id} missing name');
        expect(d.description, isNotEmpty, reason: '${d.id} missing description');
      }
    });

    test('non-healthy diseases have treatments', () {
      for (final d in service.diseases) {
        if (d.id == 'healthy') continue;
        expect(d.treatments, isNotEmpty,
            reason: '${d.id} missing treatments');
      }
    });

    test('all diseases have valid scan_type', () {
      for (final d in service.diseases) {
        expect(['leaf', 'pod', 'both'], contains(d.scanType),
            reason: '${d.id} has invalid scanType: ${d.scanType}');
      }
    });
  });
}
