import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cocoaguard/models/conversation.dart';
import 'package:cocoaguard/providers/qa_provider.dart';
import 'package:cocoaguard/services/gemma4_service.dart';
import 'package:cocoaguard/services/knowledge_service.dart';

/// Minimal KnowledgeService stub for testing (no Flutter asset loading).
class _StubKnowledgeService extends KnowledgeService {
  @override
  bool get isLoaded => true;

  @override
  String search(String question) {
    if (question.toLowerCase().contains('anthracnose')) {
      return 'Anthracnose is a fungal disease. Remove infected pods.';
    }
    return "I don't have a specific answer for that.";
  }
}

Gemma4Service _makeGemma4({
  required String responseText,
  int statusCode = 200,
}) {
  final client = MockClient((request) async {
    return http.Response(
      jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': responseText}
              ]
            }
          }
        ]
      }),
      statusCode,
    );
  });
  return Gemma4Service(apiKey: 'test-key', client: client);
}

Gemma4Service _makeFailingGemma4() {
  final client = MockClient((request) async {
    throw Exception('No internet');
  });
  return Gemma4Service(apiKey: 'test-key', client: client);
}

void main() {
  late Box<ChatMessage> chatBox;
  late Box cacheBox;
  late Directory tempDir;
  int _boxCounter = 0;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
  });

  setUp(() async {
    _boxCounter++;
    chatBox = await Hive.openBox<ChatMessage>('test_chat_$_boxCounter');
    cacheBox = await Hive.openBox('test_cache_$_boxCounter');
  });

  tearDown(() async {
    await chatBox.clear();
    await cacheBox.clear();
    await chatBox.close();
    await cacheBox.close();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('QaProvider with Gemma 4 API', () {
    test('successful API call saves message with source gemma4', () async {
      final provider = QaProvider(
        gemma4: _makeGemma4(responseText: 'Use copper fungicide.'),
        knowledge: _StubKnowledgeService(),
        chatBox: chatBox,
        cacheBox: cacheBox,
      );

      await provider.ask('How to treat black pod?');

      expect(provider.messages.length, 1);
      expect(provider.messages.first.source, 'gemma4');
      expect(provider.messages.first.answer, 'Use copper fungicide.');
      expect(provider.messages.first.question, 'How to treat black pod?');
    });

    test('successful API call caches the response', () async {
      final provider = QaProvider(
        gemma4: _makeGemma4(responseText: 'Cached answer text.'),
        knowledge: _StubKnowledgeService(),
        chatBox: chatBox,
        cacheBox: cacheBox,
      );

      await provider.ask('What is anthracnose?');

      // Check cache box has an entry
      expect(cacheBox.isNotEmpty, isTrue);
      expect(cacheBox.values.first, 'Cached answer text.');
    });
  });

  group('QaProvider fallback chain', () {
    test('network failure → falls back to knowledge base', () async {
      final provider = QaProvider(
        gemma4: _makeFailingGemma4(),
        knowledge: _StubKnowledgeService(),
        chatBox: chatBox,
        cacheBox: cacheBox,
      );

      await provider.ask('Tell me about anthracnose');

      expect(provider.messages.length, 1);
      expect(provider.messages.first.source, 'knowledge_base');
      expect(provider.messages.first.answer.toLowerCase(),
          contains('anthracnose'));
    });

    test('network failure with cached response → returns cached', () async {
      // First, populate cache
      cacheBox.put('what is anthracnose', 'Previously cached Gemma 4 answer.');

      final provider = QaProvider(
        gemma4: _makeFailingGemma4(),
        knowledge: _StubKnowledgeService(),
        chatBox: chatBox,
        cacheBox: cacheBox,
      );

      await provider.ask('What is anthracnose?');

      expect(provider.messages.first.source, 'cached');
      expect(provider.messages.first.answer,
          'Previously cached Gemma 4 answer.');
    });

    test('no API key → falls back to knowledge base', () async {
      final provider = QaProvider(
        gemma4: null,
        knowledge: _StubKnowledgeService(),
        chatBox: chatBox,
        cacheBox: cacheBox,
      );

      await provider.ask('Tell me about anthracnose');

      expect(provider.messages.first.source, 'knowledge_base');
    });

    test('no API key + cached response → returns cached', () async {
      cacheBox.put('tell me about anthracnose', 'Cached from before.');

      final provider = QaProvider(
        gemma4: null,
        knowledge: _StubKnowledgeService(),
        chatBox: chatBox,
        cacheBox: cacheBox,
      );

      await provider.ask('Tell me about anthracnose');

      expect(provider.messages.first.source, 'cached');
      expect(provider.messages.first.answer, 'Cached from before.');
    });
  });

  group('QaProvider scan context', () {
    test('setScanContext stores context', () {
      final provider = QaProvider(
        knowledge: _StubKnowledgeService(),
        chatBox: chatBox,
        cacheBox: cacheBox,
      );

      provider.setScanContext(
        disease: 'phytophthora',
        confidence: 87.5,
        scanType: 'pod',
      );

      expect(provider.scanContext, isNotNull);
      expect(provider.scanContext!.disease, 'phytophthora');
      expect(provider.scanContext!.confidence, 87.5);
      expect(provider.scanContext!.scanType, 'pod');
    });

    test('clearScanContext removes context', () {
      final provider = QaProvider(
        knowledge: _StubKnowledgeService(),
        chatBox: chatBox,
        cacheBox: cacheBox,
      );

      provider.setScanContext(
          disease: 'test', confidence: 50, scanType: 'leaf');
      provider.clearScanContext();

      expect(provider.scanContext, isNull);
    });

    test('scan context is saved with message', () async {
      final provider = QaProvider(
        gemma4: null,
        knowledge: _StubKnowledgeService(),
        chatBox: chatBox,
        cacheBox: cacheBox,
      );

      provider.setScanContext(
        disease: 'anthracnose',
        confidence: 92.0,
        scanType: 'leaf',
      );
      await provider.ask('What should I do?');

      expect(provider.messages.first.scanContext, isNotNull);
      expect(provider.messages.first.scanContext!, contains('anthracnose'));
    });
  });

  group('QaProvider history management', () {
    test('clearHistory removes all messages', () async {
      final provider = QaProvider(
        gemma4: null,
        knowledge: _StubKnowledgeService(),
        chatBox: chatBox,
        cacheBox: cacheBox,
      );

      await provider.ask('Question 1');
      await provider.ask('Question 2');
      expect(provider.messages.length, 2);

      await provider.clearHistory();
      expect(provider.messages, isEmpty);
    });

    test('empty question is ignored', () async {
      final provider = QaProvider(
        knowledge: _StubKnowledgeService(),
        chatBox: chatBox,
        cacheBox: cacheBox,
      );

      await provider.ask('   ');
      expect(provider.messages, isEmpty);
    });
  });
}
