// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StreakModelAdapter extends TypeAdapter<StreakModel> {
  @override
  final int typeId = 5;

  @override
  StreakModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StreakModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      currentStreak: fields[2] as int,
      longestStreak: fields[3] as int,
      lastFeedingDate: fields[4] as DateTime?,
      streakStartDate: fields[5] as DateTime?,
      freezeAvailable: fields[6] as int,
      frozenDays: (fields[7] as List).cast<DateTime>(),
      lastFreezeResetDate: fields[8] as DateTime?,
      synced: fields[9] == null ? false : fields[9] as bool,
      updatedAt: fields[10] as DateTime?,
      serverUpdatedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, StreakModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.currentStreak)
      ..writeByte(3)
      ..write(obj.longestStreak)
      ..writeByte(4)
      ..write(obj.lastFeedingDate)
      ..writeByte(5)
      ..write(obj.streakStartDate)
      ..writeByte(6)
      ..write(obj.freezeAvailable)
      ..writeByte(7)
      ..write(obj.frozenDays)
      ..writeByte(8)
      ..write(obj.lastFreezeResetDate)
      ..writeByte(9)
      ..write(obj.synced)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.serverUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
