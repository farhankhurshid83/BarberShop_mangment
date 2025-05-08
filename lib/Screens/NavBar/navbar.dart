import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controllers/authController.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<Map<String, dynamic>> navItems;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.navItems,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final isAdmin = authController.currentUser.value?.role != 'staff';
    final permissions = authController.currentUser.value?.allowedOptions ?? [];

    // Define icons and labels for routes
    const routeToIconLabel = {
      '/dashboard': {'icon': Icons.home, 'label': 'Home', 'permission': null},
      '/services': {'icon': Icons.cut, 'label': 'Services', 'permission': null},
      '/generate-invoice': {'icon': Icons.add_outlined, 'label': '', 'permission': null},
      '/finance': {'icon': Icons.trending_up, 'label': 'Finance', 'permission': 'Finance'},
      '/expenses': {'icon': Icons.attach_money_rounded, 'label': 'Expenses', 'permission': 'Expenses'},
      '/staff-management': {'icon': Icons.group, 'label': 'Staff', 'permission': 'Staff'},
    };

    // Filter navItems to only include valid routes
    final allowedItems = navItems.asMap().entries.where((entry) {
      final item = entry.value;
      final route = item['route'] as String;
      if (isAdmin) return true; // Admins have access to all provided items
      final permission = routeToIconLabel[route]?['permission'] as String?;
      return permission == null || permissions.contains(permission);
    }).toList();

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
          items: allowedItems.map((entry) {
            final item = entry.value;
            final route = item['route'] as String;
            final iconLabel = routeToIconLabel[route] ?? {'icon': Icons.error, 'label': 'Unknown', 'permission': null};
            final isEnabled = isAdmin || (iconLabel['permission'] == null || permissions.contains(iconLabel['permission']));
            return BottomNavigationBarItem(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  iconLabel['label'] == ''
                      ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    child: Icon(
                      iconLabel['icon'] as IconData,
                      color: Theme.of(context).colorScheme.onTertiary,
                      size: 30,
                    ),
                  )
                      : Icon(iconLabel['icon'] as IconData),
                  if (!isEnabled)
                    const Icon(
                      Icons.lock,
                      size: 16,
                      color: Colors.red,
                    ),
                ],
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
            final item = allowedItems[index].value;
            final route = item['route'] as String;
            final permission = routeToIconLabel[route]?['permission'] as String?;
            final isEnabled = isAdmin || (permission == null || permissions.contains(permission));
            if (isEnabled) {
              onItemTapped(allowedItems[index].key);
            } else {
              Get.snackbar(
                'Access Denied',
                'You do not have permission to access this feature.',
                backgroundColor: Theme.of(context).colorScheme.error,
                colorText: Theme.of(context).colorScheme.onError,
              );
            }
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