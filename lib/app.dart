import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/history_provider.dart';
import 'providers/language_provider.dart';
import 'providers/pod_scan_provider.dart';
import 'providers/qa_provider.dart';
import 'providers/scan_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/unified_screen.dart';
import 'screens/history_screen.dart';
import 'screens/library_screen.dart';
import 'services/gemma4_service.dart';
import 'services/knowledge_service.dart';
import 'services/leaf_classifier_service.dart';
import 'services/pod_classifier_service.dart';
import 'services/storage_service.dart';
import 'services/translation_service.dart';
import 'utils/app_colors.dart';

class CocoaGuardApp extends StatelessWidget {
  final LeafClassifierService leafClassifierService;
  final PodClassifierService podClassifierService;
  final StorageService storageService;
  final KnowledgeService knowledgeService;
  final Gemma4Service? gemma4Service;
  final TranslationService? translationService;
  final String? initError;

  const CocoaGuardApp({
    super.key,
    required this.leafClassifierService,
    required this.podClassifierService,
    required this.storageService,
    required this.knowledgeService,
    this.gemma4Service,
    this.translationService,
    this.initError,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(
            knowledgeService: knowledgeService,
            settingsBox: storageService.settingsBox,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ScanProvider(
            classifier: leafClassifierService,
            storage: storageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PodScanProvider(
            service: podClassifierService,
            storage: storageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              HistoryProvider(storage: storageService)..loadHistory(),
        ),
        ChangeNotifierProvider(
          create: (_) => QaProvider(
            gemma4: gemma4Service,
            knowledge: knowledgeService,
            translation: translationService,
            chatBox: storageService.chatBox,
            cacheBox: storageService.responseCacheBox,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'CocoaGuard',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: AppColors.chartreuse,
            onPrimary: AppColors.onyx,
            secondary: AppColors.toffeeBrown,
            onSecondary: AppColors.white,
            tertiary: AppColors.lemonLime,
            onTertiary: AppColors.onyx,
            error: AppColors.error,
            onError: AppColors.white,
            surface: AppColors.white,
            onSurface: AppColors.onyx,
          ),
          scaffoldBackgroundColor: AppColors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.onyx,
            foregroundColor: AppColors.chartreuse,
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.chartreuse,
              foregroundColor: AppColors.onyx,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.toffeeBrown,
            ),
          ),
        ),
        home: _AppShell(
          initError: initError,
          knowledgeService: knowledgeService,
          storageService: storageService,
        ),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  final String? initError;
  final KnowledgeService knowledgeService;
  final StorageService storageService;

  const _AppShell({
    this.initError,
    required this.knowledgeService,
    required this.storageService,
  });

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding =
        widget.storageService.settingsBox.get('onboarding_complete') != true;
    if (widget.initError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initError!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }

  void _completeOnboarding() {
    widget.storageService.settingsBox.put('onboarding_complete', true);
    setState(() => _showOnboarding = false);
  }

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // LibraryScreen rebuilds when LanguageProvider notifies (language switch).
    // Consumer ensures it gets a fresh build with the newly loaded data.
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    return Consumer<LanguageProvider>(
      builder: (context, langProvider, _) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          UnifiedScreen(onNavigate: _onNavigate),
          const HistoryScreen(),
          LibraryScreen(knowledgeService: widget.knowledgeService),
        ],
      ),
      // Only show app navigation bar for History and Library screens
      bottomNavigationBar: _currentIndex == 0
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                if (index == 1) {
                  context.read<HistoryProvider>().loadHistory();
                }
                setState(() => _currentIndex = index);
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: widget.knowledgeService.sectionTitle('navHome'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history_outlined),
                  selectedIcon: const Icon(Icons.history),
                  label: widget.knowledgeService.sectionTitle('navHistory'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.local_library_outlined),
                  selectedIcon: const Icon(Icons.local_library),
                  label: widget.knowledgeService.sectionTitle('navLibrary'),
                ),
              ],
            ),
    );
      },
    );
  }
}
