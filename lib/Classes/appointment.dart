import 'package:hive_ce/hive.dart';

part 'appointment.g.dart';

@HiveType(typeId: 0)
class Appointment extends HiveObject {
  @HiveField(0)
  String customerName;

  @HiveField(1)
  DateTime time;

  @HiveField(2)
  String service;

  @HiveField(3)
  String? avatarPath;

  @HiveField(4)
  DateTime? reminderTime; // Make nullable

  Appointment({
    required this.customerName,
    required this.time,
    required this.service,
    this.avatarPath,
    this.reminderTime,
  });
}