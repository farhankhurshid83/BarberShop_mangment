import 'package:hive_ce/hive.dart';
part 'invoice.g.dart';

@HiveType(typeId: 3)
class Invoice {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerName;

  @HiveField(2)
  final double total;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final List<Map<String, dynamic>> services;

  Invoice({
    required this.id,
    required this.customerName,
    required this.total,
    required this.date,
    required this.services,
  });
}