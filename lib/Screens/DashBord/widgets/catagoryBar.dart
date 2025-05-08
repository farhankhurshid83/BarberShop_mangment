import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Controllers/authController.dart';

// Class to define a category
class Category {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? route; // Added to map to navigation routes

  const Category({
    required this.icon,
    required this.label,
    this.onTap,
    this.route,
  });
}

class CategoryBar extends StatelessWidget {
  // List of categories
  final List<Category> categories;

  const CategoryBar({
    super.key,
    List<Category>? categories,
  }) : categories = categories ??
      const [
        Category(icon: Icons.people, label: "Customers", route: '/customers'),
        Category(icon: Icons.group_add, label: "Staff", route: '/staff'),
        Category(icon: Icons.calendar_month_rounded, label: "Appointments", route: '/admin-appointments'),
        Category(icon: Icons.receipt, label: "Invoices", route: '/invoice'),
        Category(icon: Icons.attach_money, label: "Sales", route: '/sales'),
        Category(icon: Icons.money_off, label: "Expenses", route: '/all-expenses'),
      ];

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    // Filter categories based on user permissions
    final allowedCategories = categories.where((category) {
      if (authController.currentUser.value?.role != 'staff') return true; // Admins/users have full access
      return authController.isRouteAllowed(category.route ?? '');
    }).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: allowedCategories.map((category) {
        return GestureDetector(
          onTap: category.onTap, // Handle tap action
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                child: Icon(
                  category.icon,
                  color: Theme.of(context).colorScheme.onTertiary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}