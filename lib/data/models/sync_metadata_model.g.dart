// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_metadata_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncMetadataModelAdapter extends TypeAdapter<SyncMetadataModel> {
  @override
  final int typeId = 22;

  @override
  SyncMetadataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncMetadataModel(
      lastSyncAt: fields[0] as DateTime?,
      syncToken: fields[1] as String?,
      cursor: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncMetadataModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.lastSyncAt)
      ..writeByte(1)
      ..write(obj.syncToken)
      ..writeByte(2)
      ..write(obj.cursor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMetadataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
