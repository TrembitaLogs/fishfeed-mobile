// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fish_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FishModelAdapter extends TypeAdapter<FishModel> {
  @override
  final int typeId = 2;

  @override
  FishModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FishModel(
      id: fields[0] as String,
      aquariumId: fields[1] as String,
      speciesId: fields[2] as String,
      name: fields[3] as String?,
      quantity: fields[4] as int,
      notes: fields[5] as String?,
      addedAt: fields[6] as DateTime,
      synced: fields[7] == null ? false : fields[7] as bool,
      updatedAt: fields[8] as DateTime?,
      serverUpdatedAt: fields[9] as DateTime?,
      deletedAt: fields[10] as DateTime?,
      conflictStatusValue: fields[11] == null ? 0 : fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FishModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.aquariumId)
      ..writeByte(2)
      ..write(obj.speciesId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.addedAt)
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
      other is FishModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
