// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feeding_event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeedingEventModelAdapter extends TypeAdapter<FeedingEventModel> {
  @override
  final int typeId = 4;

  @override
  FeedingEventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeedingEventModel(
      id: fields[0] as String,
      fishId: fields[1] as String,
      aquariumId: fields[2] as String,
      feedingTime: fields[3] as DateTime,
      speciesId: fields[17] as String?,
      amount: fields[4] as double?,
      foodType: fields[5] as String?,
      notes: fields[6] as String?,
      synced: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      localId: fields[9] as String?,
      completedBy: fields[10] as String?,
      completedByName: fields[11] as String?,
      completedByAvatar: fields[12] as String?,
      updatedAt: fields[13] as DateTime?,
      serverUpdatedAt: fields[14] as DateTime?,
      conflictStatusValue: fields[15] as int,
      deletedAt: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FeedingEventModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fishId)
      ..writeByte(2)
      ..write(obj.aquariumId)
      ..writeByte(3)
      ..write(obj.feedingTime)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.foodType)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.synced)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.localId)
      ..writeByte(10)
      ..write(obj.completedBy)
      ..writeByte(11)
      ..write(obj.completedByName)
      ..writeByte(12)
      ..write(obj.completedByAvatar)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.serverUpdatedAt)
      ..writeByte(15)
      ..write(obj.conflictStatusValue)
      ..writeByte(16)
      ..write(obj.deletedAt)
      ..writeByte(17)
      ..write(obj.speciesId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedingEventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
