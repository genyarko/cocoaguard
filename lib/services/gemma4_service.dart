import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// HTTP client for the Gemma 4 model via the Google AI (Gemini) REST API.
///
/// Uses the `generateContent` endpoint with the Gemma 4 model. Falls back
/// gracefully when the API is unreachable (offline / error).
class Gemma4Service {
  /// Base URL for the Google AI Generative Language API.
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Model ID — change to the correct Gemma 4 model name once available.
  /// During development this can point at gemini-2.0-flash as a placeholder.
  static const _model = 'gemma-3-4b-it';

  final String _apiKey;
  final http.Client _client;
  final Duration _timeout;

  /// Maximum number of retry attempts for transient failures.
  static const int _maxRetries = 1;

  Gemma4Service({
    required String apiKey,
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
  })  : _apiKey = apiKey,
        _client = client ?? http.Client(),
        _timeout = timeout;

  /// Send a [prompt] to Gemma 4 and return the generated text.
  ///
  /// Retries once on transient failures (timeout/network). Throws a
  /// [Gemma4Exception] on persistent failure so callers can fall back to the
  /// local knowledge base.
  Future<String> generate(String prompt) async {
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
        'temperature': 0.7,
        'maxOutputTokens': 512,
        'topP': 0.95,
        'topK': 40,
      },
    });

    Gemma4Exception? lastError;

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      // Brief delay before retry
      if (attempt > 0) {
        await Future.delayed(Duration(seconds: attempt * 2));
      }

      http.Response response;
      try {
        response = await _client
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(_timeout);
      } on TimeoutException {
        lastError = const Gemma4Exception(
          'Request timed out. Check your internet connection.',
          isTimeout: true,
        );
        continue; // retry
      } catch (e) {
        lastError = Gemma4Exception(
          'Could not reach the AI service: $e',
          isNetwork: true,
        );
        continue; // retry
      }

      if (response.statusCode == 200) {
        return _extractText(response.body);
      }

      // Auth and rate-limit errors are not retryable
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const Gemma4Exception(
          'Invalid API key. Check your Gemma 4 API key in settings.',
          isAuth: true,
        );
      }
      if (response.statusCode == 429) {
        throw const Gemma4Exception(
          'Rate limit reached. Please wait a moment and try again.',
          isRateLimit: true,
        );
      }

      // Server errors (5xx) are retryable
      if (response.statusCode >= 500) {
        lastError = Gemma4Exception(
          'API error (${response.statusCode}): ${response.reasonPhrase}',
        );
        continue;
      }

      // Other client errors are not retryable
      throw Gemma4Exception(
        'API error (${response.statusCode}): ${response.reasonPhrase}',
      );
    }

    throw lastError!;
  }

  /// Extract the generated text from the Gemini API JSON response.
  String _extractText(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const Gemma4Exception('No response generated.');
      }
      final content =
          candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw const Gemma4Exception('Empty response from AI.');
      }
      return (parts[0]['text'] as String).trim();
    } catch (e) {
      if (e is Gemma4Exception) rethrow;
      throw Gemma4Exception('Failed to parse API response: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Exception type for Gemma 4 API errors.
///
/// Flags allow callers to distinguish timeout/network/auth/rate-limit errors
/// from generic failures and react accordingly.
class Gemma4Exception implements Exception {
  final String message;
  final bool isTimeout;
  final bool isNetwork;
  final bool isAuth;
  final bool isRateLimit;

  const Gemma4Exception(
    this.message, {
    this.isTimeout = false,
    this.isNetwork = false,
    this.isAuth = false,
    this.isRateLimit = false,
  });

  @override
  String toString() => message;
}
