import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_type.dart';
import '../providers/history_provider.dart';
import '../providers/pod_scan_provider.dart';
import '../providers/scan_provider.dart';
import '../services/task_router_service.dart';
import '../widgets/scan_card.dart';
import 'emergency_screen.dart';
import 'pod_results_screen.dart';
import 'qa_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _textController = TextEditingController();
  bool _navigatedToLeafResult = false;
  bool _navigatedToPodResult = false;

  /// Tracks which scan type was last initiated so we only auto-navigate for
  /// the correct provider.
  String? _lastScanMode;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer2<ScanProvider, PodScanProvider>(
      builder: (context, leafProvider, podProvider, _) {
        _handleAutoNavigation(leafProvider, podProvider);

        final isLoading = (_lastScanMode == 'leaf' && leafProvider.isLoading) ||
            (_lastScanMode == 'pod' && podProvider.isLoading);
        final error = _lastScanMode == 'pod'
            ? podProvider.error
            : leafProvider.error;

        return Scaffold(
          body: Stack(
            children: [
            SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.eco,
                                color: Colors.green[700], size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'CocoaGuard',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown[800],
                                  ),
                            ),
                            const Spacer(),
                            const _ConnectivityIndicator(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Detect cocoa diseases instantly — offline',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Smart text input ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _handleTextSubmit,
                      decoration: InputDecoration(
                        hintText: 'Ask about cocoa farming...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () =>
                              _handleTextSubmit(_textController.text),
                        ),
                        filled: true,
                        fillColor: Colors.brown[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                // ── Quick action grid ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.eco,
                                label: 'Scan\nLeaf',
                                color: Colors.green[700]!,
                                onTap: isLoading
                                    ? null
                                    : () => _showScanSheet('leaf'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.spa,
                                label: 'Scan\nPod',
                                color: Colors.brown[600]!,
                                onTap: isLoading
                                    ? null
                                    : () => _showScanSheet('pod'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.smart_toy_outlined,
                                label: 'Ask\nExpert',
                                color: Colors.blue[600]!,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const QaScreen(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.warning_amber,
                                label: 'Emergency',
                                color: Colors.red[600]!,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const EmergencyScreen(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Error state ───────────────────────────────────────
                if (error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Card(
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(error,
                                    style: const TextStyle(
                                        color: Colors.red)),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  leafProvider.clear();
                                  podProvider.clear();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Recent scans ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Text(
                      'Recent Scans',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                Consumer<HistoryProvider>(
                  builder: (context, historyProvider, _) {
                    final recent =
                        historyProvider.records.take(5).toList();
                    if (recent.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 32),
                          child: Center(
                            child: Text(
                              'No scans yet.\nTake a photo to get started!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey[500]),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          child: ScanCard(
                            record: recent[index],
                            onTap: () => _viewRecord(
                                context, recent[index]),
                          ),
                        ),
                        childCount: recent.length,
                      ),
                    );
                  },
                ),

                // Bottom padding
                const SliverPadding(
                    padding: EdgeInsets.only(bottom: 16)),
              ],
            ),
          ),

          // ── Processing overlay ─────────────────────────────────
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _lastScanMode == 'pod'
                              ? 'Detecting pods...'
                              : 'Analyzing leaf...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.brown[800],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Running AI model on device',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
        );
      },
    );
  }

  // ── Auto-navigation on scan completion ────────────────────────────────────

  void _handleAutoNavigation(
      ScanProvider leafProvider, PodScanProvider podProvider) {
    // Leaf result ready
    if (_lastScanMode == 'leaf' &&
        leafProvider.currentResult != null &&
        !leafProvider.isLoading &&
        !_navigatedToLeafResult) {
      _navigatedToLeafResult = true;
      final nav = Navigator.of(context);
      final histProv = context.read<HistoryProvider>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nav
            .push(MaterialPageRoute(
                builder: (_) => const ResultsScreen()))
            .then((_) {
          _navigatedToLeafResult = false;
          leafProvider.clear();
          histProv.loadHistory();
        });
      });
    }

    // Pod result ready
    if (_lastScanMode == 'pod' &&
        podProvider.currentResult != null &&
        !podProvider.isLoading &&
        !_navigatedToPodResult) {
      _navigatedToPodResult = true;
      final nav = Navigator.of(context);
      final histProv = context.read<HistoryProvider>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nav
            .push(MaterialPageRoute(
                builder: (_) => const PodResultsScreen()))
            .then((_) {
          _navigatedToPodResult = false;
          podProvider.clear();
          histProv.loadHistory();
        });
      });
    }
  }

  // ── Text input → task router ──────────────────────────────────────────────

  void _handleTextSubmit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final taskType = TaskRouterService.classify(trimmed);
    _textController.clear();
    FocusScope.of(context).unfocus();

    switch (taskType) {
      case TaskType.emergency:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmergencyScreen(initialQuery: trimmed),
          ),
        );
        break;
      case TaskType.question:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QaScreen(initialQuestion: trimmed),
          ),
        );
        break;
      case TaskType.image:
      case TaskType.unknown:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Use the Scan buttons for image analysis, '
                'or ask a farming question.'),
          ),
        );
        break;
    }
  }

  // ── Scan bottom sheet ─────────────────────────────────────────────────────

  void _showScanSheet(String mode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final title = mode == 'leaf' ? 'Scan Leaf' : 'Detect Pods';
        final subtitle = mode == 'leaf'
            ? 'Classify anthracnose, CSSVD, or healthy'
            : 'YOLO detects each pod and classifies disease';

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
                  title,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 13),
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
                          _startScan(mode, fromCamera: true);
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
                          _startScan(mode, fromCamera: false);
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

  void _startScan(String mode, {required bool fromCamera}) {
    setState(() => _lastScanMode = mode);

    if (mode == 'leaf') {
      context.read<PodScanProvider>().clear();
      final prov = context.read<ScanProvider>();
      fromCamera ? prov.pickFromCamera() : prov.pickFromGallery();
    } else {
      context.read<ScanProvider>().clear();
      final prov = context.read<PodScanProvider>();
      fromCamera ? prov.pickFromCamera() : prov.pickFromGallery();
    }
  }

  // ── View saved record ─────────────────────────────────────────────────────

  void _viewRecord(BuildContext context, record) {
    if (record.scanType == 'pod') {
      context.read<PodScanProvider>().clear();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PodResultsScreen(savedRecord: record),
        ),
      );
    } else {
      context.read<ScanProvider>().clear();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(savedRecord: record),
        ),
      );
    }
  }
}

// ── Quick action card ────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      color: color.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 88,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Scan option button (bottom sheet) ────────────────────────────────────────

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

// ── Connectivity indicator ───────────────────────────────────────────────────

class _ConnectivityIndicator extends StatefulWidget {
  const _ConnectivityIndicator();

  @override
  State<_ConnectivityIndicator> createState() =>
      _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState
    extends State<_ConnectivityIndicator> {
  late final StreamSubscription<List<ConnectivityResult>> _sub;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _check();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      setState(() {
        _isOnline =
            results.any((r) => r != ConnectivityResult.none);
      });
    });
  }

  Future<void> _check() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline =
            results.any((r) => r != ConnectivityResult.none);
      });
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _isOnline ? Colors.green[700]! : Colors.red[700]!;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
