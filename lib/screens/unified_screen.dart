import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
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
  final TextEditingController _textController = TextEditingController();
  bool _navigatedToResult = false;
  String? _lastScanMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _textController.addListener(() {
      setState(() {});
    });
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _textController.dispose();
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
      } catch (_) {
        // Some devices don't support focus mode control
      }

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
              // Camera preview
              if (_isInitialized && _controller != null)
                CameraPreview(_controller!)
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
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'qa',
                        child: Row(
                          children: [
                            Icon(Icons.chat_outlined),
                            SizedBox(width: 8),
                            Text('Ask AI'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'history',
                        child: Row(
                          children: [
                            Icon(Icons.history),
                            SizedBox(width: 8),
                            Text('History'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'library',
                        child: Row(
                          children: [
                            Icon(Icons.local_library),
                            SizedBox(width: 8),
                            Text('Library'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      ),
                    ],
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
          // Text input above bottom nav
          bottomSheet: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppColors.onyx,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ask a question or describe...',
                      hintStyle: const TextStyle(color: AppColors.mediumGray),
                      filled: true,
                      fillColor: AppColors.darkGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(color: AppColors.white),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _textController.text.isNotEmpty
                      ? () {
                          final question = _textController.text.trim();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QaScreen(
                                initialQuestion: question,
                              ),
                            ),
                          );
                          _textController.clear();
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _textController.text.isNotEmpty
                          ? AppColors.chartreuse
                          : AppColors.darkGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.send,
                      color: _textController.text.isNotEmpty
                          ? AppColors.onyx
                          : AppColors.mediumGray,
                    ),
                  ),
                ),
              ],
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
                      label: 'Leaf',
                      onPressed: _showLeafScanOptions,
                    ),
                    // Pod button
                    _NavButton(
                      imageAsset: 'assets/images/pod_icon.png',
                      label: 'Pod',
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
                      label: 'History',
                      onPressed: () => widget.onNavigate(1),
                    ),
                    // Library button
                    _NavButton(
                      icon: Icons.local_library,
                      label: 'Library',
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
