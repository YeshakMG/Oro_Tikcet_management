// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_charge_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServiceChargeModelAdapter extends TypeAdapter<ServiceChargeModel> {
  @override
  final int typeId = 6;

  @override
  ServiceChargeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceChargeModel(
      departureTerminal: fields[0] as String,
      dateTime: fields[1] as DateTime,
      serviceChargeAmount: fields[2] as double,
      employeeId: fields[3] as String,
      companyId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceChargeModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.departureTerminal)
      ..writeByte(1)
      ..write(obj.dateTime)
      ..writeByte(2)
      ..write(obj.serviceChargeAmount)
      ..writeByte(3)
      ..write(obj.employeeId)
      ..writeByte(4)
      ..write(obj.companyId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceChargeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
