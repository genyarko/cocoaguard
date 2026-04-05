import 'package:flutter/foundation.dart';
import '../services/knowledge_service.dart';

/// Manages app language preference and notifies listeners when language changes.
class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;
  final KnowledgeService knowledgeService;

  LanguageProvider({required this.knowledgeService});

  AppLanguage get language => _language;

  /// Change the app language. Automatically reloads the knowledge base.
  Future<void> setLanguage(AppLanguage newLanguage) async {
    if (newLanguage == _language) return;
    _language = newLanguage;
    await knowledgeService.setLanguage(newLanguage);
    notifyListeners();
  }
}
