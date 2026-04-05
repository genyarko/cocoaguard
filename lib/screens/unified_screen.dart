import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/language_provider.dart';
import '../providers/pod_scan_provider.dart';
import '../providers/scan_provider.dart';
import '../utils/app_colors.dart';
import '../utils/image_quality_checker.dart';
import 'pod_results_screen.dart';
import 'qa_screen.dart';
import 'results_screen.dart';
import 'settings_screen.dart';

class UnifiedScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const UnifiedScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<UnifiedScreen> createState() => _UnifiedScreenState();
}

class _UnifiedScreenState extends State<UnifiedScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _permissionDenied = false;
  bool _navigatedToResult = false;
  String? _lastScanMode;

  // Zoom state
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _zoomOnPinchStart = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
      if (mounted) setState(() => _isInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _permissionDenied = true);
        return;
      }

      final backCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;

      try {
        await _controller!.setFocusMode(FocusMode.auto);
      } catch (_) {}

      try {
        _minZoom = await _controller!.getMinZoomLevel();
        _maxZoom = await _controller!.getMaxZoomLevel();
        _currentZoom = _minZoom;
      } catch (_) {}

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (e is CameraException && e.code == 'CameraAccessDenied') {
        setState(() => _permissionDenied = true);
      }
    }
  }

Future<void> _captureAndClassify() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Show capturing message
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Capturing image...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      try {
        await _controller!.lockCaptureOrientation();
      } catch (_) {}

      final xfile = await _controller!.takePicture();
      final imageFile = File(xfile.path);

      if (!mounted) return;


      // Check image quality before running inference
      try {
        final quality = await ImageQualityChecker.check(imageFile);
        if (quality.warnings.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ${quality.warnings.first}'),
              backgroundColor: Colors.orange[700],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (_) {}

      if (!mounted) return;


      // Use pod classifier for center camera (pod model includes leaves in training)
      final podProvider = context.read<PodScanProvider>();
      final leafProvider = context.read<ScanProvider>();

      // Clear both
      podProvider.clear();
      leafProvider.clear();

      // Run only pod classifier
      await podProvider.runClassification(imageFile);

      if (!mounted) return;


      // Wait a moment for state to update
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Check if pod detection succeeded
      if (podProvider.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${podProvider.error}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Route to pod results
      _lastScanMode = 'pod';
      if (mounted) {
        setState(() {}); // Trigger rebuild for auto-navigation
      }

      _navigatedToResult = false;
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

void _handleAutoNavigation(ScanProvider leafProvider, PodScanProvider podProvider) {
    if (_navigatedToResult || _lastScanMode == null) return;

    // Leaf result ready (for direct Leaf button scans)
    if (_lastScanMode == 'leaf' &&
        !leafProvider.isLoading &&
        leafProvider.currentResult != null &&
        leafProvider.error == null) {
      _navigatedToResult = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => const ResultsScreen(),
                ),
              )
              .then((_) {
            if (mounted) {
              leafProvider.clear();
              context.read<HistoryProvider>().loadHistory();
              _navigatedToResult = false;
              _lastScanMode = null;
            }
          });
        }
      });
    }

    // Pod result ready (for Pod button or center camera)
    if (_lastScanMode == 'pod' &&
        !podProvider.isLoading &&
        podProvider.currentResult != null &&
        podProvider.error == null) {
      _navigatedToResult = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => const PodResultsScreen(),
                ),
              )
              .then((_) {
            if (mounted) {
              podProvider.clear();
              context.read<HistoryProvider>().loadHistory();
              _navigatedToResult = false;
              _lastScanMode = null;
            }
          });
        }
      });
    }
  }

  void _showLeafScanOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scan Leaf',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Classify anthracnose, CSSVD, or healthy',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ScanOption(
                        icon: Icons.camera_alt,
                        label: 'Take Photo',
                        onTap: () {
                          Navigator.pop(ctx);
                          context.read<PodScanProvider>().clear();
                          _lastScanMode = 'leaf';
                          context.read<ScanProvider>().pickFromCamera();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ScanOption(
                        icon: Icons.photo_library,
                        label: 'Pick from Gallery',
                        onTap: () {
                          Navigator.pop(ctx);
                          context.read<PodScanProvider>().clear();
                          _lastScanMode = 'leaf';
                          context.read<ScanProvider>().pickFromGallery();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPodScanOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Detect Pods',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'YOLO detects each pod and classifies disease',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ScanOption(
                        icon: Icons.camera_alt,
                        label: 'Take Photo',
                        onTap: () {
                          Navigator.pop(ctx);
                          context.read<ScanProvider>().clear();
                          _lastScanMode = 'pod';
                          context.read<PodScanProvider>().pickFromCamera();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ScanOption(
                        icon: Icons.photo_library,
                        label: 'Pick from Gallery',
                        onTap: () {
                          Navigator.pop(ctx);
                          context.read<ScanProvider>().clear();
                          _lastScanMode = 'pod';
                          context.read<PodScanProvider>().pickFromGallery();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ScanProvider, PodScanProvider>(
      builder: (context, leafProvider, podProvider, _) {
        _handleAutoNavigation(leafProvider, podProvider);

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // Camera preview with pinch-to-zoom
              if (_isInitialized && _controller != null)
                GestureDetector(
                  onScaleStart: (_) {
                    _zoomOnPinchStart = _currentZoom;
                  },
                  onScaleUpdate: (details) async {
                    final newZoom = (_zoomOnPinchStart * details.scale)
                        .clamp(_minZoom, _maxZoom);
                    if (newZoom != _currentZoom) {
                      _currentZoom = newZoom;
                      await _controller!.setZoomLevel(_currentZoom);
                      setState(() {});
                    }
                  },
                  child: CameraPreview(_controller!),
                )
              else if (_permissionDenied)
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Camera permission denied',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _initCamera,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

              // Zoom level indicator (shown when zoomed in)
              if (_currentZoom > _minZoom + 0.05)
                Positioned(
                  top: 16,
                  right: 16,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.onyxTransparent(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentZoom.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

              // Tip: gallery scans give better results
              Positioned(
                bottom: 8,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.onyxTransparent(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Colors.amber, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tip: Uploading a saved photo from gallery gives more accurate results than a live capture.',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top dropdown menu
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.onyxTransparent(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.menu, color: Colors.white),
                    ),
                    onSelected: (value) {
                      if (value == 'qa') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QaScreen(),
                          ),
                        );
                      } else if (value == 'history') {
                        widget.onNavigate(1);
                      } else if (value == 'library') {
                        widget.onNavigate(2);
                      } else if (value == 'settings') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext ctx) {
                      final ks = ctx.read<LanguageProvider>().knowledgeService;
                      return [
                        PopupMenuItem(
                          value: 'qa',
                          child: Row(
                            children: [
                              const Icon(Icons.chat_outlined),
                              const SizedBox(width: 8),
                              Text(ks.sectionTitle('askAI')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'history',
                          child: Row(
                            children: [
                              const Icon(Icons.history),
                              const SizedBox(width: 8),
                              Text(ks.sectionTitle('navHistory')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'library',
                          child: Row(
                            children: [
                              const Icon(Icons.local_library),
                              const SizedBox(width: 8),
                              Text(ks.sectionTitle('navLibrary')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              const Icon(Icons.settings),
                              const SizedBox(width: 8),
                              Text(ks.sectionTitle('settings')),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ),
              ),

              // Loading indicator overlay
              if (_isProcessing || leafProvider.isLoading || podProvider.isLoading)
                Container(
                  color: AppColors.onyxTransparent(0.6),
                  child: Center(
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: AppColors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 32,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                color: AppColors.chartreuse,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _lastScanMode == 'pod'
                                  ? 'Analyzing cocoa...'
                                  : 'Analyzing leaf...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onyx,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              leafProvider.isLoading || podProvider.isLoading
                                  ? 'Processing image...'
                                  : 'Running AI models',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.darkGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Text input above bottom nav — tapping navigates to QaScreen
          // rather than opening the keyboard here (which would split the
          // camera view with a white gap behind the keyboard).
          bottomSheet: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QaScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppColors.onyx,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Ask a question or describe...',
                        style: TextStyle(color: AppColors.mediumGray),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.darkGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.onyx,
              border: Border(
                top: BorderSide(color: AppColors.mauveShadow),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Leaf button
                    _NavButton(
                      icon: Icons.eco,
                      label: context.watch<LanguageProvider>().knowledgeService.sectionTitle('navLeaf'),
                      onPressed: _showLeafScanOptions,
                    ),
                    // Pod button
                    _NavButton(
                      imageAsset: 'assets/images/pod_icon.png',
                      label: context.watch<LanguageProvider>().knowledgeService.sectionTitle('navPod'),
                      onPressed: _showPodScanOptions,
                    ),
                    // Camera button (center, larger)
                    Semantics(
                      button: true,
                      label: 'Capture photo button',
                      child: GestureDetector(
                      onTap: _isProcessing ? null : _captureAndClassify,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.chartreuse,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.chartreuseTransparent(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.camera_alt,
                          color: AppColors.onyx,
                          size: 32,
                        ),
                      ),
                    ),
                    ),
                    // History button
                    _NavButton(
                      icon: Icons.history,
                      label: context.watch<LanguageProvider>().knowledgeService.sectionTitle('navHistory'),
                      onPressed: () => widget.onNavigate(1),
                    ),
                    // Library button
                    _NavButton(
                      icon: Icons.local_library,
                      label: context.watch<LanguageProvider>().knowledgeService.sectionTitle('navLibrary'),
                      onPressed: () => widget.onNavigate(2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String label;
  final VoidCallback onPressed;

  const _NavButton({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.onPressed,
  }) : assert(icon != null || imageAsset != null);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label button',
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageAsset != null)
              Image.asset(
                imageAsset!,
                width: 24,
                height: 24,
              )
            else
              Icon(icon, color: AppColors.chartreuse, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.chartreuse,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ScanOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[50],
          foregroundColor: Colors.brown[800],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 1,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
