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

  Gemma4Service({
    required String apiKey,
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  })  : _apiKey = apiKey,
        _client = client ?? http.Client(),
        _timeout = timeout;

  /// Send a [prompt] to Gemma 4 and return the generated text.
  ///
  /// Throws a [Gemma4Exception] on failure so callers can decide whether to
  /// fall back to the local knowledge base.
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
      throw const Gemma4Exception(
        'Request timed out. Check your internet connection.',
        isTimeout: true,
      );
    } catch (e) {
      throw Gemma4Exception(
        'Could not reach the AI service: $e',
        isNetwork: true,
      );
    }

    if (response.statusCode == 200) {
      return _extractText(response.body);
    }

    // Handle specific HTTP errors
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

    throw Gemma4Exception(
      'API error (${response.statusCode}): ${response.reasonPhrase}',
    );
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
