import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:memory_capsule/Screens/DashBord/adminDashBord.dart';
import 'package:memory_capsule/Screens/expensesScreen.dart';
import 'package:memory_capsule/Screens/financeOverview.dart';
import 'package:memory_capsule/Screens/services.dart';
import '../../Controllers/authController.dart';
import '../../auth/StaffAuthManagementPage.dart';
import '../NavBar/navbar.dart';
import '../drawer/drawer.dart';
import '../gernateInvoice.dart';

class StaffNavBarPage extends StatefulWidget {
  const StaffNavBarPage({super.key});

  @override
  _StaffNavBarPageState createState() => _StaffNavBarPageState();
}

class _StaffNavBarPageState extends State<StaffNavBarPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthController authController = Get.find<AuthController>();

  // Dynamically build navigation items based on staff permissions
  List<Map<String, dynamic>> get _navItems {
    final permissions = authController.currentUser.value?.allowedOptions ?? [];
    final List<Map<String, dynamic>> items = [
      {'route': '/dashboard', 'screen': const AdminDashboard()},
      {'route': '/services', 'screen': const ServicesScreen()},
      {'route': '/generate-invoice', 'screen': const GenerateInvoiceScreen()},
    ];

    if (permissions.contains('Finance')) {
      items.add({'route': '/finance', 'screen': const FinancialOverviewPage()});
    }
    if (permissions.contains('Expenses')) {
      items.add({'route': '/expenses', 'screen': const ExpensesScreen()});
    }
    if (permissions.contains('Staff')) {
      items.add({'route': '/staff-management', 'screen': const StaffManagementScreen()});
    }
    return items;
  }

  void _onItemTapped(int index) {
    if (index < _navItems.length) {
      setState(() {
        _selectedIndex = index;
      });
    } else {
      setState(() {
        _selectedIndex = 0; // Fallback to first item if index is invalid
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Ensure _selectedIndex is valid for the current _navItems length
      if (_selectedIndex >= _navItems.length) {
        _selectedIndex = 0;
      }

      return Scaffold(
        key: _scaffoldKey,
        drawer: const CustomDrawer(),
        body: IndexedStack(
          index: _selectedIndex,
          children: _navItems.map((item) {
            return Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => item['screen'],
                );
              },
            );
          }).toList(),
        ),
        bottomNavigationBar: CustomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          navItems: _navItems,
        ),
      );
    });
  }
}