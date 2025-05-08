import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:memory_capsule/Screens/DashBord/adminDashBord.dart';
import 'package:memory_capsule/Screens/expensesScreen.dart';
import 'package:memory_capsule/Screens/financeOverview.dart';
import 'package:memory_capsule/Screens/gernateInvoice.dart';
import 'package:memory_capsule/Screens/services.dart';
import '../../Controllers/authController.dart';
import '../drawer/drawer.dart';

class StaffNavBarPage extends StatefulWidget {
  const StaffNavBarPage({super.key});

  @override
  _StaffNavBarPageState createState() => _StaffNavBarPageState();
}

class _StaffNavBarPageState extends State<StaffNavBarPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      body: Obx(() {
        // Dynamically build navigation items based on staff permissions
        final permissions = authController.currentUser.value?.allowedOptions ?? [];
        final navItems = [
          {'route': '/dashboard', 'screen': const AdminDashboard()},
          {'route': '/services', 'screen': const ServicesScreen()},
          {'route': '/generate-invoice', 'screen': const GenerateInvoiceScreen()},
          if (permissions.contains('Finance'))
            {'route': '/finance', 'screen': const FinancialOverviewPage()},
          if (permissions.contains('Expenses'))
            {'route': '/expenses', 'screen': const ExpensesScreen()},
        ];

        // Ensure _selectedIndex is valid
        if (_selectedIndex >= navItems.length) {
          _selectedIndex = 0;
        }

        // Filter allowed items
        const routeToPermission = {
          '/dashboard': null,
          '/services': 'Services',
          '/generate-invoice': 'Generate Invoice',
          '/finance': 'Finance',
          '/expenses': 'Expenses',
        };

        final allowedItems = [
          navItems[0], // Dashboard is always included
          ...navItems.sublist(1).where((item) {
            final permission = routeToPermission[item['route']];
            return permission == null || permissions.contains(permission);
          }),
        ];

        // If only one item, display it directly without navigation
        if (allowedItems.length == 1) {
          return Navigator(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => allowedItems[0]['screen'] as Widget,
              );
            },
          );
        }

        return IndexedStack(
          index: _selectedIndex,
          children: allowedItems.map<Widget>((item) {
            return Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => item['screen'] as Widget,
                );
              },
            );
          }).toList(),
        );
      }),
      bottomNavigationBar: Obx(() {
        final permissions = authController.currentUser.value?.allowedOptions ?? [];
        final navItems = [
          {'route': '/dashboard', 'screen': const AdminDashboard()},
          {'route': '/services', 'screen': const ServicesScreen()},
          {'route': '/generate-invoice', 'screen': const GenerateInvoiceScreen()},
          if (permissions.contains('Finance'))
            {'route': '/finance', 'screen': const FinancialOverviewPage()},
          if (permissions.contains('Expenses'))
            {'route': '/expenses', 'screen': const ExpensesScreen()},
        ];

        // Filter allowed items
        const routeToPermission = {
          '/dashboard': null,
          '/services': 'Services',
          '/generate-invoice': 'Generate Invoice',
          '/finance': 'Finance',
          '/expenses': 'Expenses',
        };

        final allowedItems = [
          navItems[0], // Dashboard is always included
          ...navItems.sublist(1).where((item) {
            final permission = routeToPermission[item['route']];
            return permission == null || permissions.contains(permission);
          }),
        ];

        // If only one item, hide the navigation bar
        if (allowedItems.length < 2) {
          return const SizedBox.shrink();
        }

        return StaffCustomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: (index) {
            if (index < allowedItems.length) {
              setState(() {
                _selectedIndex = index;
              });
            }
          },
          navItems: allowedItems,
        );
      }),
    );
  }
}

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

    // Filter allowed items (already filtered in parent, but ensuring consistency)
    final allowedItems = [
      navItems[0], // Dashboard is always at index 0
      ...navItems.sublist(1).where((item) {
        final route = item['route'] as String;
        final permission = routeToIconLabel[route]?['permission'] as String?;
        return permission == null || permissions.contains(permission);
      }).toList(),
    ];

    // If less than 2 items, do not render BottomNavigationBar
    if (allowedItems.length < 2) {
      return const SizedBox.shrink();
    }

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