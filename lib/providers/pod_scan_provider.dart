import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/detected_pod.dart';
import '../models/scan_record.dart';
import '../services/pod_classifier_service.dart';
import '../services/storage_service.dart';
import '../utils/image_quality_checker.dart';
import '../utils/image_utils.dart';

class PodScanProvider extends ChangeNotifier {
  final PodClassifierService _service;
  final StorageService _storage;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  PodScanProvider({
    required PodClassifierService service,
    required StorageService storage,
  })  : _service = service,
        _storage = storage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  File? _currentImage;
  File? get currentImage => _currentImage;

  Uint8List? _currentImageBytes;
  Uint8List? get currentImageBytes => _currentImageBytes;

  DetectionResult? _currentResult;
  DetectionResult? get currentResult => _currentResult;

  List<String> _qualityWarnings = [];
  List<String> get qualityWarnings => _qualityWarnings;

  Future<void> pickFromCamera() => _pickImage(ImageSource.camera);
  Future<void> pickFromGallery() => _pickImage(ImageSource.gallery);

  Future<void> _pickImage(ImageSource source) async {
    _error = null;
    _currentResult = null;
    _currentImageBytes = null;

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;

      final file = File(picked.path);
      if (!file.existsSync() || file.lengthSync() == 0) {
        _error = 'Selected image is empty or could not be read.';
        notifyListeners();
        return;
      }

      _currentImage = file;
      _currentImageBytes = await file.readAsBytes();
      _qualityWarnings = [];
      notifyListeners();

      // Check image quality before detection
      try {
        final quality = await ImageQualityChecker.check(file);
        _qualityWarnings = quality.warnings;
      } catch (_) {
        // Don't block detection if quality check fails
      }

      await _runDetection();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      _error = (msg.contains('permission') || msg.contains('denied'))
          ? 'Camera/gallery permission denied. Please grant access in Settings.'
          : 'Could not pick image: $e';
      notifyListeners();
    }
  }

  Future<void> runClassification(File imageFile) async {
    _currentImage = imageFile;
    _currentImageBytes = await imageFile.readAsBytes();
    await _runDetection();
  }

  Future<void> _runDetection() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bytes = _currentImageBytes!;

      // Defer heavy work to next event loop cycle to allow UI to render spinner.
      // Without this delay, the blocking ML inference can start before the spinner
      // has a chance to render, making the app appear frozen.
      await Future.delayed(const Duration(milliseconds: 100));

      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Could not decode image.');

      // Downscale large camera images before detection to save memory/time
      final constrained = ImageUtils.constrainSize(decoded);

      final result = await _service.detectAndClassify(constrained, originalBytes: bytes);

      if (result == null || result.pods.isEmpty) {
        _error = 'No cocoa pods detected. Try a clearer photo with pods visible.';
      } else {
        _currentResult = result;
      }
    } catch (e) {
      _error = _friendlyError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveCurrentResult() async {
    if (_currentImage == null || _currentResult == null) return;

    // Determine the primary pod to represent this scan in history
    final primary = _currentResult!.worstDisease ??
        _currentResult!.largestPod ??
        _currentResult!.pods.first;

    final appDir = await getApplicationDocumentsDirectory();
    final savedDir = Directory('${appDir.path}/scans');
    if (!savedDir.existsSync()) savedDir.createSync(recursive: true);

    final id = _uuid.v4();
    final ext = _currentImage!.path.split('.').last;
    final savedImage = await _currentImage!.copy('${savedDir.path}/$id.$ext');

    final record = ScanRecord(
      id: id,
      imagePath: savedImage.path,
      diagnosis: primary.diagnosis.className,
      confidence: primary.diagnosis.confidence,
      allScores: primary.diagnosis.probabilities,
      scannedAt: DateTime.now(),
      scanType: 'pod',
    );

    await _storage.saveRecord(record);
    notifyListeners();
  }

  void clear() {
    _currentImage = null;
    _currentImageBytes = null;
    _currentResult = null;
    _error = null;
    _qualityWarnings = [];
    notifyListeners();
  }

  String _friendlyError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('Could not decode') || msg.contains('Invalid image')) {
      return 'Could not read the image. Please try a different photo.';
    }
    if (msg.contains('not initialized') || msg.contains('not loaded')) {
      return 'Pod AI model failed to load. Please restart the app.';
    }
    return 'Detection failed. Try a clearer photo with pods clearly visible.';
  }
}
