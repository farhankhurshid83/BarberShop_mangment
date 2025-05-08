import 'package:hive_ce/hive.dart';
part 'user.g.dart';

@HiveType(typeId: 5)
class User {
  @HiveField(0)
  final String username;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String hashedPassword;

  @HiveField(3)
  final String? role;

  @HiveField(4)
  final bool? isLoggedIn;

  @HiveField(5)
  final String? profilePicturePath;

  @HiveField(6)
  final List<String>? allowedOptions; // New field for staff permissions

  User({
    required this.username,
    required this.email,
    required this.hashedPassword,
    this.role,
    this.isLoggedIn = false,
    this.profilePicturePath,
    this.allowedOptions,
  });
}