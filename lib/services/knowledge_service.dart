import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Supported languages for the offline knowledge base.
enum AppLanguage { english, french, spanish }

extension AppLanguageExt on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.french:
        return 'fr';
      case AppLanguage.spanish:
        return 'es';
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.french:
        return 'Français';
      case AppLanguage.spanish:
        return 'Español';
    }
  }
}

/// Offline knowledge base loaded from assets/data/diseases_knowledge*.json.
///
/// Provides keyword-based search over diseases, farming tips, and COCOBOD
/// resources in English, French, or Spanish. Supports no-internet operation.
class KnowledgeService {
  List<DiseaseEntry> _diseases = [];
  List<GeneralTip> _generalTips = [];
  CocobodInfo? _cocobod;
  AppLanguage _currentLanguage = AppLanguage.english;

  bool get isLoaded => _diseases.isNotEmpty;

  List<DiseaseEntry> get diseases => _diseases;
  List<GeneralTip> get generalTips => _generalTips;
  CocobodInfo? get cocobod => _cocobod;
  AppLanguage get currentLanguage => _currentLanguage;

  /// Load the JSON knowledge base from assets. Defaults to English.
  /// Call with [language] to load a specific language translation.
  Future<void> init({AppLanguage language = AppLanguage.english}) async {
    _currentLanguage = language;
    final filename = _getFilename(language);
    final raw = await rootBundle.loadString('assets/data/$filename');
    final data = jsonDecode(raw) as Map<String, dynamic>;

    _diseases = (data['diseases'] as List)
        .map((d) => DiseaseEntry.fromJson(d as Map<String, dynamic>))
        .toList();

    _generalTips = (data['general_farming'] as List)
        .map((t) => GeneralTip.fromJson(t as Map<String, dynamic>))
        .toList();

    if (data['cocobod_resources'] != null) {
      _cocobod =
          CocobodInfo.fromJson(data['cocobod_resources'] as Map<String, dynamic>);
    }
  }

  /// Find the best offline answer for [question].
  ///
  /// Scoring: each keyword hit in name / symptoms / causes / FAQ questions
  /// adds weight. Returns a formatted answer from the best-matching entry,
  /// or a general tip if no disease matches.
  String search(String question) {
    final q = question.toLowerCase();
    final tokens = _tokenize(q);

    // ── Score diseases ────────────────────────────────────────────────────
    _DiseaseMatch? best;

    for (final disease in _diseases) {
      if (disease.id == 'healthy') continue; // skip "healthy" for Q&A

      int score = 0;

      // Direct name / id match is strong
      if (q.contains(disease.id)) score += 5;
      if (q.contains(disease.name.toLowerCase())) score += 5;

      // Token overlap with searchable corpus
      for (final token in tokens) {
        if (token.length < 3) continue;
        for (final word in disease.searchableWords) {
          if (word.contains(token) || token.contains(word)) {
            score += 1;
          }
        }
      }

      // FAQ exact-ish match
      for (final faq in disease.faq) {
        final faqQ = faq.question.toLowerCase();
        int faqOverlap = 0;
        for (final token in tokens) {
          if (token.length >= 3 && faqQ.contains(token)) faqOverlap++;
        }
        if (faqOverlap >= 2) {
          // Good FAQ match — return the FAQ answer directly
          if (best == null || faqOverlap + score > best.score) {
            best = _DiseaseMatch(disease, faqOverlap + score, faq.answer);
          }
        }
      }

      if (score > 0 && (best == null || score > best.score)) {
        best = _DiseaseMatch(disease, score, null);
      }
    }

    if (best != null && best.score >= 2) {
      if (best.faqAnswer != null) return best.faqAnswer!;
      return _formatDiseaseAnswer(best.disease, q);
    }

    // ── Score general farming tips ────────────────────────────────────────
    for (final tip in _generalTips) {
      final topicLower = tip.topic.toLowerCase();
      int overlap = 0;
      for (final token in tokens) {
        if (token.length >= 3 && topicLower.contains(token)) overlap++;
      }
      if (overlap >= 2) return tip.answer;
    }

    // ── COCOBOD query ─────────────────────────────────────────────────────
    if (q.contains('cocobod') || q.contains('extension') || q.contains('report')) {
      if (_cocobod != null) {
        return 'COCOBOD (Ghana Cocoa Board) offers: '
            '${_cocobod!.services.take(3).join("; ")}. '
            'Contact them when: ${_cocobod!.whenToContact.first}.';
      }
    }

    return "I don't have a specific answer for that question in my offline "
        "library. Try asking about a specific disease (anthracnose, CSSVD, "
        "phytophthora, carmenta, moniliasis, witches' broom) or a farming "
        "topic (pruning, fertilizer, shade, harvesting). "
        "Connect to the internet for AI-powered answers from Gemma 4.";
  }

  /// Find a disease entry by its id (e.g. 'anthracnose').
  DiseaseEntry? findById(String id) {
    final lower = id.toLowerCase();
    for (final d in _diseases) {
      if (d.id == lower) return d;
    }
    return null;
  }

  // ── Internals ───────────────────────────────────────────────────────────

  List<String> _tokenize(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  String _formatDiseaseAnswer(DiseaseEntry d, String query) {
    final buf = StringBuffer();

    // Decide which aspect the user is asking about
    final askTreatment = query.contains('treat') ||
        query.contains('cure') ||
        query.contains('fix') ||
        query.contains('spray') ||
        query.contains('fungicid');
    final askPrevention = query.contains('prevent') ||
        query.contains('avoid') ||
        query.contains('protect') ||
        query.contains('stop');
    final askCause = query.contains('cause') ||
        query.contains('why') ||
        query.contains('reason') ||
        query.contains('how does');
    final askSymptom = query.contains('symptom') ||
        query.contains('sign') ||
        query.contains('look like') ||
        query.contains('identify');

    buf.writeln('${d.name} (severity: ${d.severity})');
    buf.writeln();

    if (askCause && d.causes.isNotEmpty) {
      buf.writeln('Causes:');
      for (final c in d.causes) {
        buf.writeln('• $c');
      }
    } else if (askSymptom && d.symptoms.isNotEmpty) {
      buf.writeln('Symptoms:');
      for (final s in d.symptoms) {
        buf.writeln('• $s');
      }
    } else if (askPrevention && d.prevention.isNotEmpty) {
      buf.writeln('Prevention:');
      for (final p in d.prevention) {
        buf.writeln('• $p');
      }
    } else if (askTreatment && d.treatments.isNotEmpty) {
      buf.writeln('Treatment:');
      for (final t in d.treatments) {
        buf.writeln('• $t');
      }
    } else {
      // General overview
      buf.writeln(d.description);
      if (d.treatments.isNotEmpty) {
        buf.writeln();
        buf.writeln('Treatment:');
        for (final t in d.treatments) {
          buf.writeln('• $t');
        }
      }
    }

    buf.writeln();
    buf.write('Connect to the internet for a more detailed answer from Gemma 4.');
    return buf.toString().trim();
  }

  /// Get the filename for the given language.
  static String _getFilename(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'diseases_knowledge.json';
      case AppLanguage.french:
        return 'diseases_knowledge_fr.json';
      case AppLanguage.spanish:
        return 'diseases_knowledge_es.json';
    }
  }

  /// Change the language dynamically. Reloads the knowledge base.
  Future<void> setLanguage(AppLanguage language) async {
    if (language == _currentLanguage) return;
    await init(language: language);
  }
}

// ── Data models ──────────────────────────────────────────────────────────────

class _DiseaseMatch {
  final DiseaseEntry disease;
  final int score;
  final String? faqAnswer;
  _DiseaseMatch(this.disease, this.score, this.faqAnswer);
}

class DiseaseEntry {
  final String id;
  final String name;
  final String scanType;
  final String severity;
  final String description;
  final List<String> symptoms;
  final List<String> causes;
  final List<String> treatments;
  final List<String> prevention;
  final List<FaqEntry> faq;

  /// Pre-computed lowercase words for search matching.
  late final List<String> searchableWords;

  DiseaseEntry({
    required this.id,
    required this.name,
    required this.scanType,
    required this.severity,
    required this.description,
    required this.symptoms,
    required this.causes,
    required this.treatments,
    required this.prevention,
    required this.faq,
  }) {
    final corpus = [
      name,
      description,
      ...symptoms,
      ...causes,
      ...treatments,
      ...prevention,
      ...faq.map((f) => f.question),
    ].join(' ').toLowerCase();
    searchableWords = corpus
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3)
        .toSet()
        .toList();
  }

  factory DiseaseEntry.fromJson(Map<String, dynamic> json) {
    return DiseaseEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      scanType: json['scan_type'] as String? ?? 'both',
      severity: json['severity'] as String? ?? 'unknown',
      description: json['description'] as String? ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      causes: List<String>.from(json['causes'] ?? []),
      treatments: List<String>.from(json['treatments'] ?? []),
      prevention: List<String>.from(json['prevention'] ?? []),
      faq: (json['faq'] as List?)
              ?.map((f) => FaqEntry.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FaqEntry {
  final String question;
  final String answer;

  FaqEntry({required this.question, required this.answer});

  factory FaqEntry.fromJson(Map<String, dynamic> json) {
    return FaqEntry(
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }
}

class GeneralTip {
  final String topic;
  final String answer;

  GeneralTip({required this.topic, required this.answer});

  factory GeneralTip.fromJson(Map<String, dynamic> json) {
    return GeneralTip(
      topic: json['topic'] as String,
      answer: json['answer'] as String,
    );
  }
}

class CocobodInfo {
  final String description;
  final List<String> whenToContact;
  final List<String> services;

  CocobodInfo({
    required this.description,
    required this.whenToContact,
    required this.services,
  });

  factory CocobodInfo.fromJson(Map<String, dynamic> json) {
    return CocobodInfo(
      description: json['description'] as String? ?? '',
      whenToContact: List<String>.from(json['when_to_contact'] ?? []),
      services: List<String>.from(json['services'] ?? []),
    );
  }
}
