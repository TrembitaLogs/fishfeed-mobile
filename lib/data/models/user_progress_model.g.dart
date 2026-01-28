// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProgressModelAdapter extends TypeAdapter<UserProgressModel> {
  @override
  final int typeId = 10;

  @override
  UserProgressModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProgressModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      totalXp: fields[2] as int,
      streakBonusesEarned: (fields[3] as List).cast<int>(),
      lastXpAwardedAt: fields[4] as DateTime?,
      lastLevelUpAt: fields[5] as DateTime?,
      synced: fields[6] == null ? false : fields[6] as bool,
      updatedAt: fields[7] as DateTime?,
      serverUpdatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProgressModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.totalXp)
      ..writeByte(3)
      ..write(obj.streakBonusesEarned)
      ..writeByte(4)
      ..write(obj.lastXpAwardedAt)
      ..writeByte(5)
      ..write(obj.lastLevelUpAt)
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
      other is UserProgressModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
