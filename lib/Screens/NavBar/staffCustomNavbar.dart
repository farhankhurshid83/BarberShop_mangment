import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controllers/authController.dart';

class StaffCustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<Map<String, dynamic>> navItems;

  const StaffCustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.navItems,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final permissions = authController.currentUser.value?.allowedOptions ?? [];

    // Define icons and labels for routes
    const routeToIconLabel = {
      '/dashboard': {'icon': Icons.home, 'label': 'Home', 'permission': null},
      '/services': {'icon': Icons.cut, 'label': 'Services', 'permission': 'Services'},
      '/generate-invoice': {'icon': Icons.add_circle, 'label': 'Invoice', 'permission': 'Generate Invoice'},
      '/finance': {'icon': Icons.trending_up, 'label': 'Finance', 'permission': 'Finance'},
      '/expenses': {'icon': Icons.attach_money_rounded, 'label': 'Expenses', 'permission': 'Expenses'},
    };

    // Always include dashboard, filter others based on permissions
    final allowedItems = [
      navItems[0], // Dashboard is always at index 0
      ...navItems.sublist(1).where((item) {
        final route = item['route'] as String;
        final permission = routeToIconLabel[route]?['permission'] as String?;
        return permission == null || permissions.contains(permission);
      }).toList(),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        left: false,
        right: false,
        top: false,
        bottom: true,
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: allowedItems.asMap().entries.map((entry) {
            final item = entry.value;
            final route = item['route'] as String;
            final iconLabel = routeToIconLabel[route] ?? {'icon': Icons.error, 'label': 'Unknown', 'permission': null};
            return BottomNavigationBarItem(
              icon: Icon(
                iconLabel['icon'] as IconData,
              ),
              label: iconLabel['label'] as String,
            );
          }).toList(),
          currentIndex: selectedIndex < allowedItems.length ? selectedIndex : 0,
          selectedItemColor: Theme.of(context).colorScheme.secondary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index >= allowedItems.length) return;
            onItemTapped(index);
          },
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          iconSize: 28,
        ),
      ),
    );
  }
}