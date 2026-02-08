// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      email: fields[1] as String,
      displayName: fields[2] as String?,
      avatarUrl: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      subscriptionStatus: fields[5] as SubscriptionStatus,
      freeAiScansRemaining: fields[6] as int,
      settings: fields[7] as UserSettingsModel?,
      synced: fields[8] == null ? true : fields[8] as bool,
      serverUpdatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.avatarUrl)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.subscriptionStatus)
      ..writeByte(6)
      ..write(obj.freeAiScansRemaining)
      ..writeByte(7)
      ..write(obj.settings)
      ..writeByte(8)
      ..write(obj.synced)
      ..writeByte(9)
      ..write(obj.serverUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
