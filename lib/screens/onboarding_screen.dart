import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to CocoaGuard',
      description: 'AI-powered cocoa disease detection for farmers, by farmers.',
      icon: Icons.eco,
    ),
    OnboardingPage(
      title: 'Scan & Diagnose',
      description:
          'Photograph cocoa leaves and pods. Get instant disease diagnosis with treatment recommendations.',
      icon: Icons.camera_alt,
    ),
    OnboardingPage(
      title: 'Ask Questions',
      description:
          'Ask farming questions and get intelligent answers powered by Gemma 4 AI.',
      icon: Icons.chat_bubble_outline,
    ),
    OnboardingPage(
      title: 'Works Offline',
      description:
          'Full functionality without internet. Perfect for remote farms with spotty connectivity.',
      icon: Icons.signal_wifi_off,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          // Progress indicator
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Semantics(
              label: 'Page ${_currentPage + 1} of ${_pages.length}',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    width: _currentPage == index ? 32 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.chartreuse
                          : AppColors.mediumGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Button area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: 'Go to previous page',
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.toffeeBrown,
                              side: const BorderSide(
                                color: AppColors.toffeeBrown,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: _currentPage == _pages.length - 1
                            ? 'Get started with CocoaGuard'
                            : 'Go to next page',
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == _pages.length - 1) {
                              widget.onComplete();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Semantics(
      label: '${page.title}. ${page.description}',
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_currentPage == 0)
            Image.asset(
              'cocoaguard_logo.png',
              height: 200,
              width: 200,
            )
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.chartreuse.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                page.icon,
                size: 60,
                color: AppColors.chartreuse,
              ),
            ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onyx,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.darkGray,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}
