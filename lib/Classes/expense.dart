import 'package:hive_ce/hive.dart';
part 'expense.g.dart';

@HiveType(typeId: 2)
class Expense {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String category;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
  });
}