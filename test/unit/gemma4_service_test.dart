import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cocoaguard/services/gemma4_service.dart';

void main() {
  group('Gemma4Service', () {
    test('parses successful response', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Apply copper fungicide every 2 weeks.'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = Gemma4Service(
        apiKey: 'test-key',
        client: client,
      );

      final result = await service.generate('How to treat black pod?');
      expect(result, 'Apply copper fungicide every 2 weeks.');
    });

    test('throws Gemma4Exception on 401', () async {
      final client = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final service = Gemma4Service(apiKey: 'bad-key', client: client);

      expect(
        () => service.generate('test'),
        throwsA(
          isA<Gemma4Exception>()
              .having((e) => e.isAuth, 'isAuth', isTrue),
        ),
      );
    });

    test('throws Gemma4Exception on 403', () async {
      final client = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });

      final service = Gemma4Service(apiKey: 'bad-key', client: client);

      expect(
        () => service.generate('test'),
        throwsA(
          isA<Gemma4Exception>()
              .having((e) => e.isAuth, 'isAuth', isTrue),
        ),
      );
    });

    test('throws Gemma4Exception on 429 rate limit', () async {
      final client = MockClient((request) async {
        return http.Response('Too Many Requests', 429);
      });

      final service = Gemma4Service(apiKey: 'key', client: client);

      expect(
        () => service.generate('test'),
        throwsA(
          isA<Gemma4Exception>()
              .having((e) => e.isRateLimit, 'isRateLimit', isTrue),
        ),
      );
    });

    test('throws Gemma4Exception on 500 server error', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = Gemma4Service(apiKey: 'key', client: client);

      expect(
        () => service.generate('test'),
        throwsA(isA<Gemma4Exception>()),
      );
    });

    test('throws on empty candidates', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'candidates': []}),
          200,
        );
      });

      final service = Gemma4Service(apiKey: 'key', client: client);

      expect(
        () => service.generate('test'),
        throwsA(isA<Gemma4Exception>()),
      );
    });

    test('throws network error on connection failure', () async {
      final client = MockClient((request) async {
        throw Exception('No internet');
      });

      final service = Gemma4Service(apiKey: 'key', client: client);

      expect(
        () => service.generate('test'),
        throwsA(
          isA<Gemma4Exception>()
              .having((e) => e.isNetwork, 'isNetwork', isTrue),
        ),
      );
    });

    test('includes API key in request URL', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'ok'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = Gemma4Service(apiKey: 'my-secret-key', client: client);
      await service.generate('test');

      expect(capturedUri!.queryParameters['key'], 'my-secret-key');
    });

    test('sends correct content-type header', () async {
      Map<String, String>? capturedHeaders;
      final client = MockClient((request) async {
        capturedHeaders = request.headers;
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'ok'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = Gemma4Service(apiKey: 'key', client: client);
      await service.generate('test');

      expect(capturedHeaders!['Content-Type'], 'application/json');
    });

    test('sends prompt in request body', () async {
      String? capturedBody;
      final client = MockClient((request) async {
        capturedBody = request.body;
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'ok'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = Gemma4Service(apiKey: 'key', client: client);
      await service.generate('What causes black pod?');

      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      final contents = body['contents'] as List;
      final parts = contents[0]['parts'] as List;
      expect(parts[0]['text'], 'What causes black pod?');
    });
  });
}
