// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VehicleModelAdapter extends TypeAdapter<VehicleModel> {
  @override
  final int typeId = 0;

  @override
  VehicleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VehicleModel(
      id: fields[0] as String,
      plateNumber: fields[1] as String,
      fleetTypeId: fields[2] as String,
      vehicleLevelId: fields[3] as String,
      companyId: fields[4] as String,
      seatCapacity: fields[5] as int,
      status: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.plateNumber)
      ..writeByte(2)
      ..write(obj.fleetTypeId)
      ..writeByte(3)
      ..write(obj.vehicleLevelId)
      ..writeByte(4)
      ..write(obj.companyId)
      ..writeByte(5)
      ..write(obj.seatCapacity)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
