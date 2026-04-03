import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/scan_record.dart';
import '../services/storage_service.dart';

class HistoryProvider extends ChangeNotifier {
  final StorageService _storage;

  HistoryProvider({required StorageService storage}) : _storage = storage;

  List<ScanRecord> _records = [];
  List<ScanRecord> get records => _records;

  void loadHistory() {
    _records = _storage.getAllRecords();
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    final record = _storage.getRecordById(id);
    if (record != null) {
      final file = File(record.imagePath);
      if (file.existsSync()) file.deleteSync();
    }

    await _storage.deleteRecord(id);
    loadHistory();
  }

  Future<void> clearHistory() async {
    for (final record in _records) {
      final file = File(record.imagePath);
      if (file.existsSync()) file.deleteSync();
      await _storage.deleteRecord(record.id);
    }
    _records.clear();
    notifyListeners();
  }
}
