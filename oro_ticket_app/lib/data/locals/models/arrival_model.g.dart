// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arrival_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArrivalModelAdapter extends TypeAdapter<ArrivalModel> {
  @override
  final int typeId = 2;

  @override
  ArrivalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArrivalModel(
      id: fields[0] as String,
      name: fields[1] as String,
      tariff: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ArrivalModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.tariff);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrivalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
