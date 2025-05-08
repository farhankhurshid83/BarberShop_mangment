import 'package:hive_ce_flutter/hive_flutter.dart';

part 'staff.g.dart';

@HiveType(typeId: 7)
class Staff extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double salary;

  @HiveField(2)
  String contact;

  @HiveField(3)
  String address;

  @HiveField(4)
  String role;

  @HiveField(5)
  String? profilePicturePath;

  Staff({
    required this.name,
    required this.salary,
    required this.contact,
    required this.address,
    required this.role,
    this.profilePicturePath,
  });
}