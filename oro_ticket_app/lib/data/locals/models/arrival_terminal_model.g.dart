// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arrival_terminal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LevelSpecificTariffAdapter extends TypeAdapter<LevelSpecificTariff> {
  @override
  final int typeId = 8;

  @override
  LevelSpecificTariff read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LevelSpecificTariff(
      vehicleLevelId: fields[0] as String,
      vehicleLevelName: fields[1] as String,
      fleetTypeId: fields[2] as String,
      fleetTypeName: fields[3] as String,
      tariff: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LevelSpecificTariff obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.vehicleLevelId)
      ..writeByte(1)
      ..write(obj.vehicleLevelName)
      ..writeByte(2)
      ..write(obj.fleetTypeId)
      ..writeByte(3)
      ..write(obj.fleetTypeName)
      ..writeByte(4)
      ..write(obj.tariff);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelSpecificTariffAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ArrivalTerminalModelAdapter extends TypeAdapter<ArrivalTerminalModel> {
  @override
  final int typeId = 3;

  @override
  ArrivalTerminalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArrivalTerminalModel(
      id: fields[0] as String,
      name: fields[1] as String,
      tariff: fields[2] as double,
      distance: fields[3] as double,
      tariffLevel1: fields[4] as double?,
      tariffLevel2: fields[5] as double?,
      tariffLevel3: fields[6] as double?,
      levelSpecificTariffs: (fields[7] as List?)?.cast<LevelSpecificTariff>(),
    );
  }

  @override
  void write(BinaryWriter writer, ArrivalTerminalModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.tariff)
      ..writeByte(3)
      ..write(obj.distance)
      ..writeByte(4)
      ..write(obj.tariffLevel1)
      ..writeByte(5)
      ..write(obj.tariffLevel2)
      ..writeByte(6)
      ..write(obj.tariffLevel3)
      ..writeByte(7)
      ..write(obj.levelSpecificTariffs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrivalTerminalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
