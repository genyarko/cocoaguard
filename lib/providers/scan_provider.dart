import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/scan_record.dart';
import '../services/leaf_classifier_service.dart';
import '../services/storage_service.dart';
import '../utils/image_quality_checker.dart';

class ScanProvider extends ChangeNotifier {
  final LeafClassifierService _classifier;
  final StorageService _storage;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  ScanProvider({
    required LeafClassifierService classifier,
    required StorageService storage,
  })  : _classifier = classifier,
        _storage = storage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  File? _currentImage;
  File? get currentImage => _currentImage;

  LeafClassificationResult? _currentResult;
  LeafClassificationResult? get currentResult => _currentResult;

  /// Image quality warnings from the last scan (empty if quality is fine).
  List<String> _qualityWarnings = [];
  List<String> get qualityWarnings => _qualityWarnings;

  Future<void> pickFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> pickFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    _error = null;
    _currentResult = null;

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return; // User cancelled

      final file = File(picked.path);
      if (!file.existsSync() || file.lengthSync() == 0) {
        _error = 'Selected image is empty or could not be read.';
        notifyListeners();
        return;
      }

      _currentImage = file;
      _qualityWarnings = [];
      notifyListeners();

      // Check image quality before classification
      try {
        final quality = await ImageQualityChecker.check(file);
        _qualityWarnings = quality.warnings;
      } catch (_) {
        // Don't block classification if quality check fails
      }

      await runClassification(_currentImage!);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('permission') ||
          msg.contains('denied') ||
          msg.contains('access')) {
        _error = 'Camera/gallery permission denied. Please grant access in Settings.';
      } else {
        _error = 'Could not pick image: $e';
      }
      notifyListeners();
    }
  }

  Future<void> runClassification(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Lazy-load model on first scan
    if (!_classifier.isReady) {
      try {
        await _classifier.init();
      } catch (e) {
        _error = 'Failed to load leaf AI model: $e';
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    try {
      // Run inference on a background isolate to keep UI responsive
      final result = await compute(_classifyInBackground, {
        'imagePath': imageFile.path,
        'classifier': _classifier,
      });
      _currentResult = result;
    } on UnsupportedError {
      // compute() may not work with Interpreter — fall back to main thread.
      // Defer work to next event loop to allow spinner to render first.
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        final result = _classifier.classify(imageFile);
        _currentResult = result;
      } catch (e) {
        _error = _friendlyError(e);
      }
    } catch (e) {
      // Defer work to next event loop to allow spinner to render first.
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        final result = _classifier.classify(imageFile);
        _currentResult = result;
      } catch (e2) {
        _error = _friendlyError(e2);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveCurrentResult() async {
    if (_currentImage == null || _currentResult == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final savedDir = Directory('${appDir.path}/scans');
    if (!savedDir.existsSync()) savedDir.createSync(recursive: true);

    final id = _uuid.v4();
    final ext = _currentImage!.path.split('.').last;
    final savedImage = await _currentImage!.copy('${savedDir.path}/$id.$ext');

    final record = ScanRecord(
      id: id,
      imagePath: savedImage.path,
      diagnosis: _currentResult!.diagnosis,
      confidence: _currentResult!.confidence,
      allScores: _currentResult!.allScores,
      scannedAt: DateTime.now(),
      scanType: 'leaf',
    );

    await _storage.saveRecord(record);
    notifyListeners();
  }

  void clear() {
    _currentImage = null;
    _currentResult = null;
    _error = null;
    _qualityWarnings = [];
    notifyListeners();
  }

  String _friendlyError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('Could not decode image') || msg.contains('Invalid image')) {
      return 'Could not read the image. Please try a different photo.';
    }
    if (msg.contains('not initialized')) {
      return 'The AI model failed to load. Please restart the app.';
    }
    return 'Classification failed. Please try again with a clearer photo.';
  }
}

// Top-level function for compute() isolate
LeafClassificationResult _classifyInBackground(Map<String, dynamic> params) {
  final classifier = params['classifier'] as LeafClassifierService;
  final file = File(params['imagePath'] as String);
  return classifier.classify(file);
}
