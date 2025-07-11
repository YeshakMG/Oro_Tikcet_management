// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arrival_terminal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
    );
  }

  @override
  void write(BinaryWriter writer, ArrivalTerminalModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.tariff)
      ..writeByte(3)
      ..write(obj.distance);
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
