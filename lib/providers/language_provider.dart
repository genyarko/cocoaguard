import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../services/knowledge_service.dart';

/// Manages app language preference, persists it across restarts,
/// and reloads the knowledge base when the language changes.
class LanguageProvider extends ChangeNotifier {
  static const _key = 'app_language';

  final KnowledgeService knowledgeService;
  final Box _settingsBox;
  AppLanguage _language = AppLanguage.english;

  LanguageProvider({
    required this.knowledgeService,
    required Box settingsBox,
  }) : _settingsBox = settingsBox {
    // Restore saved language preference
    final saved = _settingsBox.get(_key) as String?;
    if (saved != null) {
      _language = AppLanguage.values.firstWhere(
        (l) => l.code == saved,
        orElse: () => AppLanguage.english,
      );
    }
  }

  AppLanguage get language => _language;

  /// Initialize knowledge base with the persisted language.
  /// Call once at startup after constructing the provider.
  Future<void> init() async {
    await knowledgeService.init(language: _language);
  }

  /// Change the app language. Reloads the knowledge base and persists the choice.
  Future<void> setLanguage(AppLanguage newLanguage) async {
    if (newLanguage == _language) return;
    _language = newLanguage;
    await _settingsBox.put(_key, newLanguage.code);
    await knowledgeService.setLanguage(newLanguage);
    notifyListeners();
  }
}
