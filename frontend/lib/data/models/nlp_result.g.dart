// GENERATED CODE - Hive adapter for NlpHistoryItem
// In a real project: run `flutter pub run build_runner build`
// This is a manual implementation to avoid the build_runner step.

part of 'nlp_result.dart';


class NlpHistoryItemAdapter extends TypeAdapter<NlpHistoryItem> {
  @override
  final int typeId = 0;

  @override
  NlpHistoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NlpHistoryItem(
      rapport: fields[0] as String,
      categorie: fields[1] as String,
      confidence: (fields[2] as num).toDouble(),
      timestamp: fields[3] as DateTime,
      keywords: (fields[4] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, NlpHistoryItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.rapport)
      ..writeByte(1)
      ..write(obj.categorie)
      ..writeByte(2)
      ..write(obj.confidence)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.keywords);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NlpHistoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
