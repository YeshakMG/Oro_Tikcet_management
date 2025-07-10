import 'package:hive/hive.dart';

part 'arrival_model.g.dart';

@HiveType(typeId: 2)
class ArrivalModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? tariff;

  ArrivalModel({
    required this.id,
    required this.name,
    this.tariff,
  });
}
