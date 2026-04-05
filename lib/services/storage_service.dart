import 'package:hive_flutter/hive_flutter.dart';
import '../models/conversation.dart';
import '../models/scan_record.dart';

class StorageService {
  static const String _boxName = 'scan_records';
  static const String _chatBoxName = 'chat_messages';
  static const String _responseCacheBoxName = 'response_cache';
  static const String _settingsBoxName = 'app_settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ScanRecordAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    await Hive.openBox<ScanRecord>(_boxName);
    await Hive.openBox<ChatMessage>(_chatBoxName);
    await Hive.openBox(_responseCacheBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  Box<ScanRecord> get _box => Hive.box<ScanRecord>(_boxName);

  Box<ChatMessage> get chatBox => Hive.box<ChatMessage>(_chatBoxName);

  /// String→String cache for Gemma 4 responses (normalized question → answer).
  Box get responseCacheBox => Hive.box(_responseCacheBoxName);

  /// Key-value settings (language, etc.).
  Box get settingsBox => Hive.box(_settingsBoxName);

  Future<void> saveRecord(ScanRecord record) async {
    await _box.put(record.id, record);
  }

  List<ScanRecord> getAllRecords() {
    final records = _box.values.toList();
    records.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return records;
  }

  ScanRecord? getRecordById(String id) {
    return _box.get(id);
  }

  Future<void> deleteRecord(String id) async {
    await _box.delete(id);
  }
}
