import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controllers/authController.dart';
import '../../Controllers/dataController.dart';
import '../../Controllers/themeController.dart';
import '../gernateInvoice.dart';
import 'widgets/catagoryBar.dart';
import 'widgets/shopBanner.dart';
import 'widgets/today_appointment.dart';
import 'widgets/today_summery.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final DataController dataController = Get.find<DataController>();
    final ThemeController themeController = Get.find<ThemeController>();
    final AuthController authController = Get.find<AuthController>();

    String getGreeting() {
      final username = authController.currentUser.value?.username;
      if (username == null || username.isEmpty) {
        return "Hi, Barber";
      }
      return "Hi, ${username[0].toUpperCase()}${username.substring(1).toLowerCase()}";
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Obx(() => Text(
          getGreeting(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        )),
        actions: [
          Obx(() => Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              width: 36, // Size of the circle
              height: 36, // Size of the circle
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeController.secondaryColor.value,
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),// Space between icon and circle edge
              child: IconButton(
                padding: EdgeInsets.zero, // Remove default padding from IconButton
                constraints: const BoxConstraints(), // Remove default constraints
                icon: Icon(
                  themeController.isDarkMode.value ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).colorScheme.onTertiary,
                  size: 24, // Icon size
                ),
                onPressed: themeController.toggleTheme,
              ),
            ),
          )),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const ShopBannerWidget(),
              const SizedBox(height: 20),
              CategoryBar(
                categories: [
                  Category(icon: Icons.people, label: "Clients", onTap: () => Get.toNamed('/customers')),
                  Category(icon: Icons.group_add, label: "Team", onTap: () => Get.toNamed('/staff')),
                  Category(icon: Icons.calendar_month_rounded, label: "Booking", onTap: () => Get.toNamed('/admin-appointments')),
                ],
              ),
              SizedBox(height: 10,),
              CategoryBar(
                categories: [
                  Category(icon: Icons.receipt, label: "Bills", onTap: () => Get.toNamed('/invoice')),
                  Category(icon: Icons.attach_money, label: "Revenue", onTap: () => Get.toNamed('/sales')),
                  Category(icon: Icons.money_off, label: "Costs", onTap: () => Get.toNamed('/all-expenses')),
                ],
              ),
              const SizedBox(height: 20),
              UpcomingAppointmentsWidget(),
              const SizedBox(height: 20),
              TodaysSummaryWidget(
                invoices: dataController.invoices,
                expenses: dataController.expenses,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}