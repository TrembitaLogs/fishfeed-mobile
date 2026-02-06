// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleModelAdapter extends TypeAdapter<ScheduleModel> {
  @override
  final int typeId = 24;

  @override
  ScheduleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleModel(
      id: fields[0] as String,
      fishId: fields[1] as String,
      aquariumId: fields[2] as String,
      time: fields[3] as String,
      intervalDays: fields[4] as int,
      anchorDate: fields[5] as DateTime,
      foodType: fields[6] as String,
      portionHint: fields[7] as String?,
      active: fields[8] as bool,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      createdByUserId: fields[11] as String,
      synced: fields[12] as bool,
      serverUpdatedAt: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fishId)
      ..writeByte(2)
      ..write(obj.aquariumId)
      ..writeByte(3)
      ..write(obj.time)
      ..writeByte(4)
      ..write(obj.intervalDays)
      ..writeByte(5)
      ..write(obj.anchorDate)
      ..writeByte(6)
      ..write(obj.foodType)
      ..writeByte(7)
      ..write(obj.portionHint)
      ..writeByte(8)
      ..write(obj.active)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.createdByUserId)
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
      other is ScheduleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
