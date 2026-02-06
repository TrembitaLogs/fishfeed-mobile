// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feeding_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeedingLogModelAdapter extends TypeAdapter<FeedingLogModel> {
  @override
  final int typeId = 25;

  @override
  FeedingLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeedingLogModel(
      id: fields[0] as String,
      scheduleId: fields[1] as String,
      fishId: fields[2] as String,
      aquariumId: fields[3] as String,
      scheduledFor: fields[4] as DateTime,
      action: fields[5] as String,
      actedAt: fields[6] as DateTime,
      actedByUserId: fields[7] as String,
      actedByUserName: fields[8] as String?,
      deviceId: fields[9] as String,
      notes: fields[10] as String?,
      createdAt: fields[11] as DateTime,
      synced: fields[12] as bool,
      serverUpdatedAt: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FeedingLogModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.scheduleId)
      ..writeByte(2)
      ..write(obj.fishId)
      ..writeByte(3)
      ..write(obj.aquariumId)
      ..writeByte(4)
      ..write(obj.scheduledFor)
      ..writeByte(5)
      ..write(obj.action)
      ..writeByte(6)
      ..write(obj.actedAt)
      ..writeByte(7)
      ..write(obj.actedByUserId)
      ..writeByte(8)
      ..write(obj.actedByUserName)
      ..writeByte(9)
      ..write(obj.deviceId)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.synced)
      ..writeByte(13)
      ..write(obj.serverUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedingLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
