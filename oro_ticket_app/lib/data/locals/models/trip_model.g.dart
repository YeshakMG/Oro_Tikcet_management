// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripModelAdapter extends TypeAdapter<TripModel> {
  @override
  final int typeId = 4;

  @override
  TripModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripModel(
      plateNumber: fields[0] as String,
      plateRegion: fields[1] as String,
      vehicleLevel: fields[2] as String,
      associationName: fields[3] as String,
      seatCapacity: fields[4] as int,
      fleetTypeName: fields[5] as String,
      dateTime: fields[6] as DateTime,
      km: fields[7] as double,
      tariff: fields[8] as double,
      serviceCharge: fields[9] as double,
      totalPaid: fields[10] as double,
      departureTerminal: fields[11] as String,
      arrivalTerminal: fields[12] as String,
      employeeName: fields[13] as String,
      companyName: fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TripModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.plateNumber)
      ..writeByte(1)
      ..write(obj.plateRegion)
      ..writeByte(2)
      ..write(obj.vehicleLevel)
      ..writeByte(3)
      ..write(obj.associationName)
      ..writeByte(4)
      ..write(obj.seatCapacity)
      ..writeByte(5)
      ..write(obj.fleetTypeName)
      ..writeByte(6)
      ..write(obj.dateTime)
      ..writeByte(7)
      ..write(obj.km)
      ..writeByte(8)
      ..write(obj.tariff)
      ..writeByte(9)
      ..write(obj.serviceCharge)
      ..writeByte(10)
      ..write(obj.totalPaid)
      ..writeByte(11)
      ..write(obj.departureTerminal)
      ..writeByte(12)
      ..write(obj.arrivalTerminal)
      ..writeByte(13)
      ..write(obj.employeeName)
      ..writeByte(14)
      ..write(obj.companyName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
