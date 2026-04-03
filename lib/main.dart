import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'services/gemma4_service.dart';
import 'services/knowledge_service.dart';
import 'services/leaf_classifier_service.dart';
import 'services/pod_classifier_service.dart';
import 'services/storage_service.dart';

void main() async {
  final startupTimer = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await StorageService.init();

  // Both classifiers lazy-load their models on first scan to keep startup fast.
  final leafClassifier = LeafClassifierService();
  final podClassifier = PodClassifierService();
  String? initError;

  final storageService = StorageService();

  // Knowledge base — loads disease data from assets for offline Q&A.
  final knowledgeService = KnowledgeService();
  try {
    await knowledgeService.init();
  } catch (e) {
    initError = '${initError ?? ''} Knowledge base failed: $e';
  }

  // Gemma 4 API — reads key from .env file.
  // If no key is set, the service is null and Q&A falls back to knowledge base.
  Gemma4Service? gemma4;
  final apiKey = dotenv.env['GEMMA4_API_KEY'] ?? '';
  if (apiKey.isNotEmpty) {
    gemma4 = Gemma4Service(apiKey: apiKey);
  }

  startupTimer.stop();
  debugPrint('[PERF] App startup (pre-runApp): ${startupTimer.elapsedMilliseconds}ms');

  runApp(CocoaGuardApp(
    leafClassifierService: leafClassifier,
    podClassifierService: podClassifier,
    storageService: storageService,
    knowledgeService: knowledgeService,
    gemma4Service: gemma4,
    initError: initError,
  ));
}
