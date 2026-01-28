// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_operation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncOperationModelAdapter extends TypeAdapter<SyncOperationModel> {
  @override
  final int typeId = 8;

  @override
  SyncOperationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncOperationModel(
      id: fields[0] as String,
      operationType: fields[1] as SyncOperationType,
      entityType: fields[2] as String,
      entityId: fields[3] as String,
      payload: fields[4] as String,
      timestamp: fields[5] as DateTime,
      retryCount: fields[6] as int,
      status: fields[7] as SyncOperationStatus,
      errorMessage: fields[8] as String?,
      lastAttempt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncOperationModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.operationType)
      ..writeByte(2)
      ..write(obj.entityType)
      ..writeByte(3)
      ..write(obj.entityId)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.errorMessage)
      ..writeByte(9)
      ..write(obj.lastAttempt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncOperationTypeAdapter extends TypeAdapter<SyncOperationType> {
  @override
  final int typeId = 20;

  @override
  SyncOperationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncOperationType.create;
      case 1:
        return SyncOperationType.update;
      case 2:
        return SyncOperationType.delete;
      default:
        return SyncOperationType.create;
    }
  }

  @override
  void write(BinaryWriter writer, SyncOperationType obj) {
    switch (obj) {
      case SyncOperationType.create:
        writer.writeByte(0);
        break;
      case SyncOperationType.update:
        writer.writeByte(1);
        break;
      case SyncOperationType.delete:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncOperationStatusAdapter extends TypeAdapter<SyncOperationStatus> {
  @override
  final int typeId = 21;

  @override
  SyncOperationStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncOperationStatus.pending;
      case 1:
        return SyncOperationStatus.inProgress;
      case 2:
        return SyncOperationStatus.completed;
      case 3:
        return SyncOperationStatus.failed;
      default:
        return SyncOperationStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SyncOperationStatus obj) {
    switch (obj) {
      case SyncOperationStatus.pending:
        writer.writeByte(0);
        break;
      case SyncOperationStatus.inProgress:
        writer.writeByte(1);
        break;
      case SyncOperationStatus.completed:
        writer.writeByte(2);
        break;
      case SyncOperationStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
