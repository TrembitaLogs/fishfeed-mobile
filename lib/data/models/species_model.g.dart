// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'species_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SpeciesModelAdapter extends TypeAdapter<SpeciesModel> {
  @override
  final int typeId = 7;

  @override
  SpeciesModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpeciesModel(
      id: fields[0] as String,
      name: fields[1] as String,
      imageUrl: fields[9] as String?,
      feedingFrequency: fields[2] as String?,
      foodType: fields[6] as FoodTypeModel?,
      portionHint: fields[7] as PortionHintModel?,
      defaultPortionGrams: fields[8] as double?,
      optimalTemperature: fields[3] as double?,
      careLevel: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SpeciesModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.feedingFrequency)
      ..writeByte(3)
      ..write(obj.optimalTemperature)
      ..writeByte(4)
      ..write(obj.careLevel)
      ..writeByte(6)
      ..write(obj.foodType)
      ..writeByte(7)
      ..write(obj.portionHint)
      ..writeByte(8)
      ..write(obj.defaultPortionGrams)
      ..writeByte(9)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeciesModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FoodTypeModelAdapter extends TypeAdapter<FoodTypeModel> {
  @override
  final int typeId = 26;

  @override
  FoodTypeModel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FoodTypeModel.flakes;
      case 1:
        return FoodTypeModel.pellets;
      case 2:
        return FoodTypeModel.live;
      case 3:
        return FoodTypeModel.frozen;
      case 4:
        return FoodTypeModel.mixed;
      default:
        return FoodTypeModel.flakes;
    }
  }

  @override
  void write(BinaryWriter writer, FoodTypeModel obj) {
    switch (obj) {
      case FoodTypeModel.flakes:
        writer.writeByte(0);
        break;
      case FoodTypeModel.pellets:
        writer.writeByte(1);
        break;
      case FoodTypeModel.live:
        writer.writeByte(2);
        break;
      case FoodTypeModel.frozen:
        writer.writeByte(3);
        break;
      case FoodTypeModel.mixed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodTypeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PortionHintModelAdapter extends TypeAdapter<PortionHintModel> {
  @override
  final int typeId = 27;

  @override
  PortionHintModel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PortionHintModel.small;
      case 1:
        return PortionHintModel.medium;
      case 2:
        return PortionHintModel.large;
      default:
        return PortionHintModel.small;
    }
  }

  @override
  void write(BinaryWriter writer, PortionHintModel obj) {
    switch (obj) {
      case PortionHintModel.small:
        writer.writeByte(0);
        break;
      case PortionHintModel.medium:
        writer.writeByte(1);
        break;
      case PortionHintModel.large:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortionHintModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
