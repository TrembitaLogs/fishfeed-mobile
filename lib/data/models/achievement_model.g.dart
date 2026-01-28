// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AchievementModelAdapter extends TypeAdapter<AchievementModel> {
  @override
  final int typeId = 6;

  @override
  AchievementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AchievementModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as String,
      title: fields[3] as String,
      description: fields[4] as String?,
      unlockedAt: fields[5] as DateTime?,
      iconUrl: fields[6] as String?,
      progress: fields[7] as double,
      synced: fields[8] == null ? false : fields[8] as bool,
      updatedAt: fields[9] as DateTime?,
      serverUpdatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AchievementModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.unlockedAt)
      ..writeByte(6)
      ..write(obj.iconUrl)
      ..writeByte(7)
      ..write(obj.progress)
      ..writeByte(8)
      ..write(obj.synced)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.serverUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
