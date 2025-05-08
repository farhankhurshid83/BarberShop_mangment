import 'package:hive_ce/hive.dart';
import 'invoice.dart';

part 'customer.g.dart';

@HiveType(typeId: 1)
class Customer {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String phone;

  @HiveField(2)
  final String? email;

  @HiveField(3)
  final int visitCount;

  @HiveField(4)
  final List<Invoice> invoices;

  @HiveField(5)
  final List<String> services;

  Customer({
    required this.name,
    required this.phone,
    this.email,
    this.visitCount = 0,
    this.invoices = const [],
    this.services = const [],
  });

  String getMostPurchasedService() {
    if (services.isEmpty) return "None";
    final serviceCount = <String, int>{};
    for (var service in services) {
      serviceCount[service] = (serviceCount[service] ?? 0) + 1;
    }
    return serviceCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  @override
  String toString() {
    return 'Customer(name: $name, phone: $phone, email: $email, visitCount: $visitCount, invoices: ${invoices.length}, services: $services)';
  }
}