// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feeding_schedule_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeedingScheduleModelAdapter extends TypeAdapter<FeedingScheduleModel> {
  @override
  final int typeId = 23;

  @override
  FeedingScheduleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeedingScheduleModel(
      id: fields[0] as String,
      aquariumId: fields[1] as String,
      timesPerDay: fields[2] as int,
      scheduledTimes: (fields[3] as List).cast<String>(),
      foodType: fields[4] as String,
      portionHint: fields[5] as String?,
      synced: fields[6] == null ? false : fields[6] as bool,
      updatedAt: fields[7] as DateTime?,
      serverUpdatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FeedingScheduleModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.aquariumId)
      ..writeByte(2)
      ..write(obj.timesPerDay)
      ..writeByte(3)
      ..write(obj.scheduledTimes)
      ..writeByte(4)
      ..write(obj.foodType)
      ..writeByte(5)
      ..write(obj.portionHint)
      ..writeByte(6)
      ..write(obj.synced)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.serverUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedingScheduleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
