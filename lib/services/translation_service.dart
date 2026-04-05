import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Translates text between languages using the Gemini API.
///
/// Used as a bridge for Twi ↔ English since Gemma doesn't understand Twi.
/// Uses gemini-2.0-flash for fast, cheap translation via the same Google AI
/// key that powers Gemma.
class TranslationService {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Use a fast/cheap Gemini model for translation — no need for a large model.
  static const _model = 'gemini-2.5-flash';

  final String _apiKey;
  final http.Client _client;
  final Duration _timeout;

  /// Maximum retry attempts for transient failures.
  static const int _maxRetries = 1;

  /// Language code → full name for prompt clarity.
  static const _langNames = {
    'en': 'English',
    'fr': 'French',
    'es': 'Spanish',
    'tw': 'Twi',
  };

  TranslationService({
    required String apiKey,
    http.Client? client,
    Duration timeout = const Duration(seconds: 8),
  })  : _apiKey = apiKey,
        _client = client ?? http.Client(),
        _timeout = timeout;

  /// Translate [text] from [from] language to [to] language.
  ///
  /// Language codes use ISO 639-1 (e.g. 'en', 'fr', 'tw').
  /// Returns the original text unchanged if [from] == [to].
  /// On failure, returns `null` so callers can fall back gracefully.
  Future<String?> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    if (from == to || text.trim().isEmpty) return text;

    final fromName = _langNames[from] ?? from;
    final toName = _langNames[to] ?? to;

    final prompt =
        'Translate the following $fromName text to $toName. '
        'Return ONLY the translated text, no explanations or notes.\n\n'
        '$text';

    final url =
        Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 512,
      },
    });

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 1));
      }

      try {
        final response = await _client
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          return _extractText(response.body);
        }

        // Auth errors — not retryable
        if (response.statusCode == 401 || response.statusCode == 403) {
          debugPrint('[TranslationService] Auth error: ${response.statusCode}');
          return null;
        }

        // Server errors — retryable
        if (response.statusCode >= 500) {
          debugPrint(
              '[TranslationService] Server error: ${response.statusCode}');
          continue;
        }

        // Other client errors — not retryable
        debugPrint(
            '[TranslationService] API error: ${response.statusCode} ${response.body}');
        return null;
      } on TimeoutException {
        debugPrint('[TranslationService] Timeout (attempt $attempt)');
        continue;
      } catch (e) {
        debugPrint('[TranslationService] Network error: $e');
        continue;
      }
    }

    return null; // all retries exhausted
  }

  /// Extract text from the Gemini generateContent response.
  String? _extractText(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;
      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return null;
      return (parts[0]['text'] as String).trim();
    } catch (e) {
      debugPrint('[TranslationService] Parse error: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
