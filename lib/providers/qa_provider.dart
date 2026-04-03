import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/conversation.dart';
import '../services/gemma4_service.dart';
import '../services/knowledge_service.dart';
import '../utils/prompt_templates.dart';

/// Manages Q&A state: sends questions to Gemma 4, falls back to the local
/// knowledge base when offline, caches Gemma 4 responses for future offline
/// use, and stores conversation history in Hive.
class QaProvider extends ChangeNotifier {
  final Gemma4Service? _gemma4;
  final KnowledgeService _knowledge;
  final Box<ChatMessage> _chatBox;
  final Box _cacheBox; // String→String: normalized question → cached answer
  final Uuid _uuid = const Uuid();

  QaProvider({
    Gemma4Service? gemma4,
    required KnowledgeService knowledge,
    required Box<ChatMessage> chatBox,
    required Box cacheBox,
  })  : _gemma4 = gemma4,
        _knowledge = knowledge,
        _chatBox = chatBox,
        _cacheBox = cacheBox;

  // ── State ──────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Optional scan context set when the user navigates to Q&A after a scan.
  ScanContext? _scanContext;
  ScanContext? get scanContext => _scanContext;

  /// All messages sorted oldest-first (for display in chat).
  List<ChatMessage> get messages {
    final all = _chatBox.values.toList();
    all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return all;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Set scan context so the next question includes disease info.
  void setScanContext({
    required String disease,
    required double confidence,
    required String scanType,
  }) {
    _scanContext = ScanContext(
      disease: disease,
      confidence: confidence,
      scanType: scanType,
    );
    notifyListeners();
  }

  void clearScanContext() {
    _scanContext = null;
    notifyListeners();
  }

  /// Ask a question. Resolution order:
  /// 1. Gemma 4 API (if key configured + online)
  /// 2. Cached Gemma 4 response (if same/similar question was asked before)
  /// 3. Local knowledge base (keyword search)
  Future<void> ask(String question) async {
    if (question.trim().isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final trimmed = question.trim();
    String answer;
    String source;

    // Build prompt
    final prompt = _scanContext != null
        ? PromptTemplates.questionAfterScan(
            userQuestion: trimmed,
            disease: _scanContext!.disease,
            confidence: _scanContext!.confidence,
            scanType: _scanContext!.scanType,
          )
        : PromptTemplates.question(trimmed);

    if (_gemma4 != null) {
      // ── Try Gemma 4 API ──────────────────────────────────────────────
      try {
        answer = await _gemma4.generate(prompt);
        source = 'gemma4';

        // Cache the response for future offline use
        final cacheKey = _normalizeForCache(trimmed);
        await _cacheBox.put(cacheKey, answer);
      } on Gemma4Exception catch (e) {
        if (e.isAuth) {
          _error = e.message;
          answer = _fallback(trimmed);
          source = answer.startsWith("I don't have") ? 'knowledge_base' : 'knowledge_base';
        } else {
          // Network / timeout / other → try cache then knowledge base
          answer = _cachedOrKnowledge(trimmed);
          source = _lastSource;
        }
      }
    } else {
      // No API key → cache then knowledge base
      answer = _cachedOrKnowledge(trimmed);
      source = _lastSource;
    }

    // Save to conversation history
    final msg = ChatMessage(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      question: trimmed,
      answer: answer,
      source: source,
      scanContext: _scanContext?.toString(),
    );
    await _chatBox.put(msg.id, msg);

    _isLoading = false;
    notifyListeners();
  }

  /// Delete a single message.
  Future<void> deleteMessage(String id) async {
    await _chatBox.delete(id);
    notifyListeners();
  }

  /// Clear all conversation history.
  Future<void> clearHistory() async {
    await _chatBox.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Fallback helpers ───────────────────────────────────────────────────────

  /// Tracks source of the last fallback call (used by [ask]).
  String _lastSource = 'knowledge_base';

  /// Try cached Gemma 4 response first, then local knowledge base.
  String _cachedOrKnowledge(String question) {
    final cacheKey = _normalizeForCache(question);
    final cached = _cacheBox.get(cacheKey) as String?;
    if (cached != null) {
      _lastSource = 'cached';
      return cached;
    }
    _lastSource = 'knowledge_base';
    return _fallback(question);
  }

  /// Query the local knowledge base.
  String _fallback(String question) {
    if (!_knowledge.isLoaded) {
      return 'The offline knowledge base is still loading. Please try again.';
    }
    return _knowledge.search(question);
  }

  /// Normalize question text for cache key lookup.
  /// Lowercases, strips punctuation/extra whitespace.
  String _normalizeForCache(String question) {
    return question
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// Holds context from a recent scan so the Q&A prompt can reference it.
class ScanContext {
  final String disease;
  final double confidence;
  final String scanType;

  const ScanContext({
    required this.disease,
    required this.confidence,
    required this.scanType,
  });

  @override
  String toString() =>
      '$scanType scan: $disease (${confidence.toStringAsFixed(1)}%)';
}
