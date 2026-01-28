// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsModelAdapter extends TypeAdapter<UserSettingsModel> {
  @override
  final int typeId = 3;

  @override
  UserSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettingsModel(
      notificationsEnabled: fields[0] as bool,
      feedingReminderMinutesBefore: fields[1] as int,
      darkModeEnabled: fields[2] as bool?,
      language: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettingsModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.notificationsEnabled)
      ..writeByte(1)
      ..write(obj.feedingReminderMinutesBefore)
      ..writeByte(2)
      ..write(obj.darkModeEnabled)
      ..writeByte(3)
      ..write(obj.language);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
