import 'package:hive/hive.dart';

part 'scan_record.g.dart';

@HiveType(typeId: 0)
class ScanRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imagePath;

  @HiveField(2)
  final String diagnosis;

  @HiveField(3)
  final double confidence;

  @HiveField(4)
  final List<double> allScores;

  @HiveField(5)
  final DateTime scannedAt;

  /// 'leaf' or 'pod' — distinguishes which scan mode produced this record.
  /// Defaults to 'leaf' for records created before pod scanning was added.
  @HiveField(6)
  final String scanType;

  ScanRecord({
    required this.id,
    required this.imagePath,
    required this.diagnosis,
    required this.confidence,
    required this.allScores,
    required this.scannedAt,
    this.scanType = 'leaf',
  });
}
