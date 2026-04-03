// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanRecordAdapter extends TypeAdapter<ScanRecord> {
  @override
  final int typeId = 0;

  @override
  ScanRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanRecord(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      diagnosis: fields[2] as String,
      confidence: fields[3] as double,
      allScores: (fields[4] as List).cast<double>(),
      scannedAt: fields[5] as DateTime,
      scanType: fields[6] == null ? 'leaf' : fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ScanRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.diagnosis)
      ..writeByte(3)
      ..write(obj.confidence)
      ..writeByte(4)
      ..write(obj.allScores)
      ..writeByte(5)
      ..write(obj.scannedAt)
      ..writeByte(6)
      ..write(obj.scanType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
