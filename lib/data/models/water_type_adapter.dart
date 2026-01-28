import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/domain/entities/water_type.dart';

/// Hive TypeAdapter for [WaterType] enum.
class WaterTypeAdapter extends TypeAdapter<WaterType> {
  @override
  final int typeId = 11;

  @override
  WaterType read(BinaryReader reader) {
    final index = reader.readByte();
    return WaterType.values[index];
  }

  @override
  void write(BinaryWriter writer, WaterType obj) {
    writer.writeByte(obj.index);
  }
}
