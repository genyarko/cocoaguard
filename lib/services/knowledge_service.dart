import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Supported languages for the offline knowledge base.
enum AppLanguage { english, french, spanish, twi }

extension AppLanguageExt on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.french:
        return 'fr';
      case AppLanguage.spanish:
        return 'es';
      case AppLanguage.twi:
        return 'tw';
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
      case AppLanguage.twi:
        return 'Twi';
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
    final cocobodKeywords = ['cocobod', 'extension', 'report', 'signaler', 'vulgarisation', 'reportar', 'extensión', 'bɔ amanneɛ', 'nkɔso'];
    if (cocobodKeywords.any((k) => q.contains(k))) {
      if (_cocobod != null) {
        final l = _labels;
        return '${l['cocobodOffers']}'
            '${_cocobod!.services.take(3).join("; ")}. '
            '${l['contactWhen']}${_cocobod!.whenToContact.first}.';
      }
    }

    return _labels['noAnswer']!;
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
    final l = _labels;

    // Multilingual keyword sets for intent detection
    final askTreatment = _matchesAny(query, [
      'treat', 'cure', 'fix', 'spray', 'fungicid',         // en
      'traiter', 'soigner', 'guérir', 'pulvéris', 'fongicid', // fr
      'tratar', 'curar', 'arreglar', 'fumigar', 'fungicida',  // es
      'sa', 'ayaresa', 'aduro', 'pete',                      // tw
    ]);
    final askPrevention = _matchesAny(query, [
      'prevent', 'avoid', 'protect', 'stop',                // en
      'prévenir', 'éviter', 'protéger', 'arrêter',          // fr
      'prevenir', 'evitar', 'proteger', 'detener',           // es
      'bɔ ho ban', 'sianka', 'twe ho',                       // tw
    ]);
    final askCause = _matchesAny(query, [
      'cause', 'why', 'reason', 'how does',                 // en
      'cause', 'pourquoi', 'raison', 'comment',              // fr
      'causa', 'por qué', 'razón', 'cómo',                   // es
      'dɛn nti', 'nea ɛde ba', 'botae',                      // tw
    ]);
    final askSymptom = _matchesAny(query, [
      'symptom', 'sign', 'look like', 'identify',           // en
      'symptôme', 'signe', 'ressemble', 'identifier',        // fr
      'síntoma', 'señal', 'parece', 'identificar',           // es
      'nsɛnkyerɛnne', 'agyirae', 'sɛn na', 'hu',            // tw
    ]);

    buf.writeln('${d.name} (${l['severity']}: ${d.severity})');
    buf.writeln();

    if (askCause && d.causes.isNotEmpty) {
      buf.writeln('${l['causes']}:');
      for (final c in d.causes) {
        buf.writeln('• $c');
      }
    } else if (askSymptom && d.symptoms.isNotEmpty) {
      buf.writeln('${l['symptoms']}:');
      for (final s in d.symptoms) {
        buf.writeln('• $s');
      }
    } else if (askPrevention && d.prevention.isNotEmpty) {
      buf.writeln('${l['prevention']}:');
      for (final p in d.prevention) {
        buf.writeln('• $p');
      }
    } else if (askTreatment && d.treatments.isNotEmpty) {
      buf.writeln('${l['treatment']}:');
      for (final t in d.treatments) {
        buf.writeln('• $t');
      }
    } else {
      buf.writeln(d.description);
      if (d.treatments.isNotEmpty) {
        buf.writeln();
        buf.writeln('${l['treatment']}:');
        for (final t in d.treatments) {
          buf.writeln('• $t');
        }
      }
    }

    buf.writeln();
    buf.write(l['connectPrompt']!);
    return buf.toString().trim();
  }

  bool _matchesAny(String query, List<String> keywords) {
    return keywords.any((k) => query.contains(k));
  }

  /// Translated UI labels used by search responses and the library screen.
  Map<String, String> get _labels => _allLabels[_currentLanguage]!;

  /// Section titles for the library screen in the current language.
  String sectionTitle(String key) => _labels[key] ?? key;

  static const _allLabels = <AppLanguage, Map<String, String>>{
    AppLanguage.english: {
      // Results screen
      'resultTitle': 'Result',
      'imageQualityIssues': 'Image Quality Issues',
      'lowConfidenceResult': 'Low Confidence Result',
      'lowConfidenceHint': 'This result is uncertain. Consider retaking the photo with better lighting and focus.',
      'lowConfidenceTip': 'Low confidence — try a clearer photo',
      'potentiallyInfected': 'Potentially Infected',
      'classScores': 'Class Scores',
      'scanAnother': 'Scan Another',
      'saveResult': 'Save Result',
      'resultSaved': 'Result saved!',
      'askAboutDisease': 'Ask about this disease',
      'treatmentTitle': 'Treatment & Recommendations',
      'severityLabel': 'Severity',
      'confidence': 'confidence',
      // Disease display names
      'diseaseAnthracnose': 'Anthracnose (Black Pod)',
      'diseaseCssvd': 'CSSVD',
      'diseaseHealthy': 'Healthy',
      'diseasePhytophthora': 'Phytophthora (Black Pod Rot)',
      'diseaseCarmenta': 'Carmenta (Pod Borer)',
      'diseaseMoniliasis': 'Moniliasis (Frosty Pod)',
      'diseaseWitchesBroom': "Witches' Broom",
      'diseaseGuide': 'Disease Guide',
      'farmingTips': 'Farming Best Practices',
      'cocobodResources': 'COCOBOD Resources',
      'offlineNote': 'All content available offline — no internet needed',
      'severity': 'severity',
      'causes': 'Causes',
      'symptoms': 'Symptoms',
      'prevention': 'Prevention',
      'treatment': 'Treatment',
      'faq': 'Frequently Asked',
      'cocobodOffers': 'COCOBOD (Ghana Cocoa Board) offers: ',
      'contactWhen': 'Contact them when: ',
      'connectPrompt': 'Connect to the internet for a more detailed answer from Gemma 4.',
      'noAnswer':
          "I don't have a specific answer for that question in my offline "
          "library. Try asking about a specific disease (anthracnose, CSSVD, "
          "phytophthora, carmenta, moniliasis, witches' broom) or a farming "
          "topic (pruning, fertilizer, shade, harvesting). "
          "Connect to the internet for AI-powered answers from Gemma 4.",
      'diseases': 'diseases',
      'tips': 'tips',
      'ghanaCocoaBoard': 'Ghana Cocoa Board',
      'whenToContact': 'When to Contact COCOBOD',
      'servicesAvailable': 'Services Available',
      'navHome': 'Home',
      'navHistory': 'History',
      'navLibrary': 'Library',
      'navLeaf': 'Leaf',
      'navPod': 'Pod',
      'askAI': 'Ask AI',
      'settings': 'Settings',
      'language': 'Language',
      'offlineLibLang': 'Offline Library Language',
      'dataManagement': 'Data Management',
      'clearScanHistory': 'Clear Scan History',
      'clearScanHistorySub': 'Remove all saved scans',
      'clearChatHistory': 'Clear Chat History',
      'clearChatHistorySub': 'Remove all Q&A conversations',
      'support': 'Support',
      'helpGuide': 'Help & Guide',
      'helpGuideSub': 'How to scan, tips, and FAQs',
      'privacyPolicy': 'Privacy Policy',
      'privacyPolicySub': 'How your data is handled',
      'about': 'About',
      'clearScanConfirm': 'Clear Scan History?',
      'clearScanConfirmBody': 'This will permanently delete all saved scans. This action cannot be undone.',
      'clearChatConfirm': 'Clear Chat History?',
      'clearChatConfirmBody': 'This will permanently delete all Q&A conversations. This action cannot be undone.',
      'cancel': 'Cancel',
      'clear': 'Clear',
      'scanHistoryCleared': 'Scan history cleared',
      'chatHistoryCleared': 'Chat history cleared',
      'onboardingWelcome': 'Welcome to CocoaGuard',
      'onboardingWelcomeSub': 'AI-powered cocoa disease detection for farmers, by farmers.',
      'onboardingChooseLang': 'Choose Your Language',
      'onboardingScan': 'Scan & Diagnose',
      'onboardingScanSub': 'Photograph cocoa leaves and pods. Get instant disease diagnosis with treatment recommendations.',
      'onboardingAsk': 'Ask Questions',
      'onboardingAskSub': 'Ask farming questions and get intelligent answers powered by Gemma 4 AI.',
      'onboardingOffline': 'Works Offline',
      'onboardingOfflineSub': 'Full functionality without internet. Perfect for remote farms with spotty connectivity.',
      'onboardingGetStarted': 'Get Started',
      'onboardingNext': 'Next',
      'onboardingBack': 'Back',
    },
    AppLanguage.french: {
      'resultTitle': 'Résultat',
      'imageQualityIssues': 'Problèmes de qualité d\'image',
      'lowConfidenceResult': 'Résultat peu fiable',
      'lowConfidenceHint': 'Ce résultat est incertain. Essayez de reprendre la photo avec un meilleur éclairage et une meilleure mise au point.',
      'lowConfidenceTip': 'Faible confiance — essayez une photo plus nette',
      'potentiallyInfected': 'Potentiellement infecté',
      'classScores': 'Scores par classe',
      'scanAnother': 'Scanner à nouveau',
      'saveResult': 'Enregistrer',
      'resultSaved': 'Résultat enregistré !',
      'askAboutDisease': 'Poser une question sur cette maladie',
      'treatmentTitle': 'Traitement et recommandations',
      'severityLabel': 'Gravité',
      'confidence': 'confiance',
      'diseaseAnthracnose': 'Anthracnose (Pourriture noire)',
      'diseaseCssvd': 'CSSVD',
      'diseaseHealthy': 'Sain',
      'diseasePhytophthora': 'Phytophthora (Pourriture noire des cabosses)',
      'diseaseCarmenta': 'Carmenta (Foreur de cabosses)',
      'diseaseMoniliasis': 'Moniliasis (Pourriture givrée)',
      'diseaseWitchesBroom': 'Balai de sorcière',
      'diseaseGuide': 'Guide des Maladies',
      'farmingTips': 'Bonnes Pratiques Agricoles',
      'cocobodResources': 'Ressources COCOBOD',
      'offlineNote': 'Tout le contenu disponible hors ligne — pas besoin d\'internet',
      'severity': 'gravité',
      'causes': 'Causes',
      'symptoms': 'Symptômes',
      'prevention': 'Prévention',
      'treatment': 'Traitement',
      'faq': 'Questions Fréquentes',
      'cocobodOffers': 'COCOBOD (Office du Cacao du Ghana) propose : ',
      'contactWhen': 'Contactez-les lorsque : ',
      'connectPrompt': 'Connectez-vous à Internet pour une réponse plus détaillée de Gemma 4.',
      'noAnswer':
          "Je n'ai pas de réponse spécifique à cette question dans ma "
          "bibliothèque hors ligne. Essayez de poser une question sur une "
          "maladie spécifique (anthracnose, CSSVD, phytophthora, carmenta, "
          "moniliasis, balai de sorcière) ou un sujet agricole (élagage, "
          "engrais, ombrage, récolte). "
          "Connectez-vous à Internet pour des réponses IA de Gemma 4.",
      'diseases': 'maladies',
      'tips': 'conseils',
      'ghanaCocoaBoard': 'Office du Cacao du Ghana',
      'whenToContact': 'Quand contacter COCOBOD',
      'servicesAvailable': 'Services Disponibles',
      'navHome': 'Accueil',
      'navHistory': 'Historique',
      'navLibrary': 'Bibliothèque',
      'navLeaf': 'Feuille',
      'navPod': 'Cabosse',
      'askAI': 'Demander à l\'IA',
      'settings': 'Paramètres',
      'language': 'Langue',
      'offlineLibLang': 'Langue de la bibliothèque hors ligne',
      'dataManagement': 'Gestion des données',
      'clearScanHistory': 'Effacer l\'historique des scans',
      'clearScanHistorySub': 'Supprimer tous les scans enregistrés',
      'clearChatHistory': 'Effacer l\'historique du chat',
      'clearChatHistorySub': 'Supprimer toutes les conversations Q&R',
      'support': 'Aide',
      'helpGuide': 'Aide & Guide',
      'helpGuideSub': 'Comment scanner, conseils et FAQ',
      'privacyPolicy': 'Politique de confidentialité',
      'privacyPolicySub': 'Comment vos données sont gérées',
      'about': 'À propos',
      'clearScanConfirm': 'Effacer l\'historique des scans ?',
      'clearScanConfirmBody': 'Cela supprimera définitivement tous les scans enregistrés. Cette action est irréversible.',
      'clearChatConfirm': 'Effacer l\'historique du chat ?',
      'clearChatConfirmBody': 'Cela supprimera définitivement toutes les conversations Q&R. Cette action est irréversible.',
      'cancel': 'Annuler',
      'clear': 'Effacer',
      'scanHistoryCleared': 'Historique des scans effacé',
      'chatHistoryCleared': 'Historique du chat effacé',
      'onboardingWelcome': 'Bienvenue sur CocoaGuard',
      'onboardingWelcomeSub': 'Détection des maladies du cacao par IA, pour les agriculteurs, par les agriculteurs.',
      'onboardingChooseLang': 'Choisissez Votre Langue',
      'onboardingScan': 'Scanner et Diagnostiquer',
      'onboardingScanSub': 'Photographiez les feuilles et cabosses de cacao. Obtenez un diagnostic instantané avec des recommandations de traitement.',
      'onboardingAsk': 'Poser des Questions',
      'onboardingAskSub': 'Posez des questions agricoles et obtenez des réponses intelligentes grâce à l\'IA Gemma 4.',
      'onboardingOffline': 'Fonctionne Hors Ligne',
      'onboardingOfflineSub': 'Fonctionnalité complète sans internet. Parfait pour les exploitations isolées.',
      'onboardingGetStarted': 'Commencer',
      'onboardingNext': 'Suivant',
      'onboardingBack': 'Retour',
    },
    AppLanguage.spanish: {
      'resultTitle': 'Resultado',
      'imageQualityIssues': 'Problemas de calidad de imagen',
      'lowConfidenceResult': 'Resultado poco confiable',
      'lowConfidenceHint': 'Este resultado es incierto. Intente retomar la foto con mejor iluminación y enfoque.',
      'lowConfidenceTip': 'Baja confianza — intente una foto más clara',
      'potentiallyInfected': 'Potencialmente infectado',
      'classScores': 'Puntuaciones por clase',
      'scanAnother': 'Escanear otro',
      'saveResult': 'Guardar',
      'resultSaved': '¡Resultado guardado!',
      'askAboutDisease': 'Preguntar sobre esta enfermedad',
      'treatmentTitle': 'Tratamiento y recomendaciones',
      'severityLabel': 'Gravedad',
      'confidence': 'confianza',
      'diseaseAnthracnose': 'Antracnosis (Mazorca negra)',
      'diseaseCssvd': 'CSSVD',
      'diseaseHealthy': 'Saludable',
      'diseasePhytophthora': 'Phytophthora (Pudrición negra)',
      'diseaseCarmenta': 'Carmenta (Barrenador de mazorca)',
      'diseaseMoniliasis': 'Moniliasis (Pudrición helada)',
      'diseaseWitchesBroom': 'Escoba de bruja',
      'diseaseGuide': 'Guía de Enfermedades',
      'farmingTips': 'Buenas Prácticas Agrícolas',
      'cocobodResources': 'Recursos COCOBOD',
      'offlineNote': 'Todo el contenido disponible sin conexión — no necesita internet',
      'severity': 'gravedad',
      'causes': 'Causas',
      'symptoms': 'Síntomas',
      'prevention': 'Prevención',
      'treatment': 'Tratamiento',
      'faq': 'Preguntas Frecuentes',
      'cocobodOffers': 'COCOBOD (Junta de Cacao de Ghana) ofrece: ',
      'contactWhen': 'Contáctelos cuando: ',
      'connectPrompt': 'Conéctese a Internet para una respuesta más detallada de Gemma 4.',
      'noAnswer':
          "No tengo una respuesta específica para esa pregunta en mi "
          "biblioteca sin conexión. Intente preguntar sobre una enfermedad "
          "específica (antracnosis, CSSVD, phytophthora, carmenta, "
          "moniliasis, escoba de bruja) o un tema agrícola (poda, "
          "fertilizante, sombra, cosecha). "
          "Conéctese a Internet para respuestas de IA de Gemma 4.",
      'diseases': 'enfermedades',
      'tips': 'consejos',
      'ghanaCocoaBoard': 'Junta de Cacao de Ghana',
      'whenToContact': 'Cuándo contactar a COCOBOD',
      'servicesAvailable': 'Servicios Disponibles',
      'navHome': 'Inicio',
      'navHistory': 'Historial',
      'navLibrary': 'Biblioteca',
      'navLeaf': 'Hoja',
      'navPod': 'Mazorca',
      'askAI': 'Preguntar a la IA',
      'settings': 'Configuración',
      'language': 'Idioma',
      'offlineLibLang': 'Idioma de la biblioteca sin conexión',
      'dataManagement': 'Gestión de datos',
      'clearScanHistory': 'Borrar historial de escaneos',
      'clearScanHistorySub': 'Eliminar todos los escaneos guardados',
      'clearChatHistory': 'Borrar historial de chat',
      'clearChatHistorySub': 'Eliminar todas las conversaciones Q&R',
      'support': 'Soporte',
      'helpGuide': 'Ayuda y Guía',
      'helpGuideSub': 'Cómo escanear, consejos y preguntas frecuentes',
      'privacyPolicy': 'Política de privacidad',
      'privacyPolicySub': 'Cómo se manejan sus datos',
      'about': 'Acerca de',
      'clearScanConfirm': '¿Borrar historial de escaneos?',
      'clearScanConfirmBody': 'Esto eliminará permanentemente todos los escaneos guardados. Esta acción no se puede deshacer.',
      'clearChatConfirm': '¿Borrar historial de chat?',
      'clearChatConfirmBody': 'Esto eliminará permanentemente todas las conversaciones Q&R. Esta acción no se puede deshacer.',
      'cancel': 'Cancelar',
      'clear': 'Borrar',
      'scanHistoryCleared': 'Historial de escaneos borrado',
      'chatHistoryCleared': 'Historial de chat borrado',
      'onboardingWelcome': 'Bienvenido a CocoaGuard',
      'onboardingWelcomeSub': 'Detección de enfermedades del cacao con IA, para agricultores, por agricultores.',
      'onboardingChooseLang': 'Elija Su Idioma',
      'onboardingScan': 'Escanear y Diagnosticar',
      'onboardingScanSub': 'Fotografíe hojas y mazorcas de cacao. Obtenga un diagnóstico instantáneo con recomendaciones de tratamiento.',
      'onboardingAsk': 'Hacer Preguntas',
      'onboardingAskSub': 'Haga preguntas agrícolas y obtenga respuestas inteligentes con IA Gemma 4.',
      'onboardingOffline': 'Funciona Sin Conexión',
      'onboardingOfflineSub': 'Funcionalidad completa sin internet. Perfecto para fincas remotas con conectividad limitada.',
      'onboardingGetStarted': 'Empezar',
      'onboardingNext': 'Siguiente',
      'onboardingBack': 'Atrás',
    },
    AppLanguage.twi: {
      'resultTitle': 'Nea Ɛbae',
      'imageQualityIssues': 'Mfonini no ho nsɛm',
      'lowConfidenceResult': 'Nea ɛbae no nnyɛ nokorɛ paa',
      'lowConfidenceHint': 'Saa nea ɛbae yi nnyɛ nokorɛ paa. Twa foto no bio wɔ hann pa ne focus pa mu.',
      'lowConfidenceTip': 'Ɛnnyɛ nokorɛ paa — twa foto pa bi',
      'potentiallyInfected': 'Ebia yare bi wɔ mu',
      'classScores': 'Akyerɛ biara nsa ano',
      'scanAnother': 'Hwɛ foforɔ',
      'saveResult': 'Kora so',
      'resultSaved': 'Woakora nea ɛbae no!',
      'askAboutDisease': 'Bisa saa nyarewa yi ho asɛm',
      'treatmentTitle': 'Ayaresa ne afotu',
      'severityLabel': 'Ahoɔden',
      'confidence': 'gyidie',
      'diseaseAnthracnose': 'Anthracnose (Koko Aba Tuntum Yare)',
      'diseaseCssvd': 'CSSVD',
      'diseaseHealthy': 'Apɔ Mu Dɔ',
      'diseasePhytophthora': 'Phytophthora (Koko Aba Tuntum Porɔeɛ)',
      'diseaseCarmenta': 'Carmenta (Koko Aba Mu Sonsono)',
      'diseaseMoniliasis': 'Moniliasis (Koko Aba Porɔeɛ)',
      'diseaseWitchesBroom': 'Nsamanba Prae',
      'diseaseGuide': 'Nyarewa Nkyerɛwde',
      'farmingTips': 'Afuom Adwuma Pa',
      'cocobodResources': 'COCOBOD Nhyehyɛe',
      'offlineNote': 'Nsɛm nyinaa wɔ ha a internet nhia',
      'severity': 'ahoɔden',
      'causes': 'Nea ɛde ba',
      'symptoms': 'Nsɛnkyerɛnne',
      'prevention': 'Ɛkwan a yɛbɔ ho ban',
      'treatment': 'Ayaresa',
      'faq': 'Nsɛm a wobisa mpɛn pii',
      'cocobodOffers': 'COCOBOD (Ghana Koko Board) de eyi ma: ',
      'contactWhen': 'Frɛ wɔn sɛ: ',
      'connectPrompt': 'Fa internet so na nya mmuae a emu dɔ firi Gemma 4.',
      'noAnswer':
          "Menni mmuae pɔtee mma saa asɛmmisa yi wɔ me offline nhoma korabea mu. "
          "Bisa nyarewa bi ho asɛm (anthracnose, CSSVD, phytophthora, carmenta, "
          "moniliasis, witches' broom) anaasɛ afuom adwuma bi ho (twatwa, "
          "nnoboa, nwunu, twabere). "
          "Fa internet so na nya AI mmuae firi Gemma 4.",
      'diseases': 'nyarewa',
      'tips': 'afotu',
      'ghanaCocoaBoard': 'Ghana Koko Board',
      'whenToContact': 'Bere a wobɛfrɛ COCOBOD',
      'servicesAvailable': 'Dwumadie a Wɔwɔ',
      'navHome': 'Fie',
      'navHistory': 'Abakɔsɛm',
      'navLibrary': 'Nhoma Korabea',
      'navLeaf': 'Nhahan',
      'navPod': 'Koko Aba',
      'askAI': 'Bisa AI',
      'settings': 'Nhyehyɛe',
      'language': 'Kasa',
      'offlineLibLang': 'Offline nhoma korabea kasa',
      'dataManagement': 'Data nhyehyɛe',
      'clearScanHistory': 'Pepa scan abakɔsɛm',
      'clearScanHistorySub': 'Yi scan a woakoraa nyinaa',
      'clearChatHistory': 'Pepa nkɔmmɔ abakɔsɛm',
      'clearChatHistorySub': 'Yi Q&A nkɔmmɔ nyinaa',
      'support': 'Mmoa',
      'helpGuide': 'Mmoa ne Nkyerɛwde',
      'helpGuideSub': 'Sɛnea wobɛscan, afotu, ne nsɛm a wobisa mpɛn pii',
      'privacyPolicy': 'Kokoamsɛm nhyehyɛe',
      'privacyPolicySub': 'Sɛnea wɔhwɛ wo data so',
      'about': 'Fa ho nsɛm',
      'clearScanConfirm': 'Pepa scan abakɔsɛm?',
      'clearScanConfirmBody': 'Eyi bɛpepa scan a woakoraa nyinaa. Wontumi nsan anyi.',
      'clearChatConfirm': 'Pepa nkɔmmɔ abakɔsɛm?',
      'clearChatConfirmBody': 'Eyi bɛpepa Q&A nkɔmmɔ nyinaa. Wontumi nsan anyi.',
      'cancel': 'Gyae',
      'clear': 'Pepa',
      'scanHistoryCleared': 'Scan abakɔsɛm apepa',
      'chatHistoryCleared': 'Nkɔmmɔ abakɔsɛm apepa',
      'onboardingWelcome': 'Akwaaba CocoaGuard',
      'onboardingWelcomeSub': 'AI a ɛhwehwɛ koko nyarewa ma afuofoɔ, afuofoɔ na ɛyɛe.',
      'onboardingChooseLang': 'Yi Wo Kasa',
      'onboardingScan': 'Hwɛ na Hu Nyarewa',
      'onboardingScanSub': 'Twa koko nhahan ne aba foto. Nya nyarewa ho nimdeɛ ntɛm ne ayaresa ho afotu.',
      'onboardingAsk': 'Bisa Nsɛmmisa',
      'onboardingAskSub': 'Bisa afuom adwuma ho nsɛmmisa na nya nimdeɛ mmuae a Gemma 4 AI de ma wo.',
      'onboardingOffline': 'Ɛyɛ Adwuma a Internet Nni Hɔ',
      'onboardingOfflineSub': 'Ɛyɛ adwuma nyinaa a internet nhia. Ɛyɛ ma afuom a internet nni hɔ daa.',
      'onboardingGetStarted': 'Hyɛ Ase',
      'onboardingNext': 'Nea Edi Hɔ',
      'onboardingBack': 'San',
    },
  };

  /// Get the filename for the given language.
  static String _getFilename(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'diseases_knowledge.json';
      case AppLanguage.french:
        return 'diseases_knowledge_fr.json';
      case AppLanguage.spanish:
        return 'diseases_knowledge_es.json';
      case AppLanguage.twi:
        return 'diseases_knowledge_tw.json';
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
