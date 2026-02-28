// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aquarium_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AquariumModelAdapter extends TypeAdapter<AquariumModel> {
  @override
  final int typeId = 1;

  @override
  AquariumModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AquariumModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      capacity: fields[3] as double?,
      waterType: fields[4] as WaterType,
      photoKey: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      synced: fields[7] == null ? false : fields[7] as bool,
      updatedAt: fields[8] as DateTime?,
      serverUpdatedAt: fields[9] as DateTime?,
      deletedAt: fields[10] as DateTime?,
      conflictStatusValue: fields[11] == null ? 0 : fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AquariumModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.capacity)
      ..writeByte(4)
      ..write(obj.waterType)
      ..writeByte(5)
      ..write(obj.photoKey)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.synced)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.serverUpdatedAt)
      ..writeByte(10)
      ..write(obj.deletedAt)
      ..writeByte(11)
      ..write(obj.conflictStatusValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AquariumModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
