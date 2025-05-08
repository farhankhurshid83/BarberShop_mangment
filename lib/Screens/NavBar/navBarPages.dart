import 'package:flutter/material.dart';
import '../DashBord/adminDashBord.dart';
import '../drawer/drawer.dart';
import '../expensesScreen.dart';
import '../financeOverview.dart';
import '../gernateInvoice.dart';
import '../services.dart';
import 'navbar.dart';

class AdminNavBarPage extends StatefulWidget {
  const AdminNavBarPage({super.key});

  @override
  _AdminNavBarPageState createState() => _AdminNavBarPageState();
}

class _AdminNavBarPageState extends State<AdminNavBarPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Define navigation items
  final List<Map<String, dynamic>> _navItems = [
    {'route': '/dashboard', 'screen': const AdminDashboard()},
    {'route': '/services', 'screen': const ServicesScreen()},
    {'route': '/generate-invoice', 'screen': const GenerateInvoiceScreen()},
    {'route': '/finance', 'screen': const FinancialOverviewPage()},
    {'route': '/expenses', 'screen': const ExpensesScreen()},
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      body: _navItems[_selectedIndex]['screen'] as Widget,
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        navItems: _navItems,
      ),
    );
  }
}