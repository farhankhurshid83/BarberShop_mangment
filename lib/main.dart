import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:memory_capsule/Screens/drawer/screen/profileScreen.dart';
import 'package:memory_capsule/services/notificationServices.dart';
import 'package:path_provider/path_provider.dart';
import 'Classes/category.dart' as AppCategory;
import 'Classes/staff.dart';
import 'Controllers/appointmentController.dart';
import 'Controllers/authController.dart';
import 'Controllers/dataController.dart';
import 'Controllers/themeController.dart';
import 'Screens/DashBord/Screens/staff.dart';
import 'Screens/DashBord/adminDashBord.dart';
import 'Screens/DashBord/appointmentScreen.dart';
import 'Screens/NavBar/navBarPages.dart';
import 'Screens/NavBar/staffNavBar.dart';
import 'Screens/allExpensesScreen.dart';
import 'Screens/allInvoices.dart';
import 'Screens/customerScreen.dart';
import 'Screens/drawer/screen/customizeAppPage.dart';
import 'Screens/expensesScreen.dart';
import 'Screens/financeOverview.dart';
import 'Screens/gernateInvoice.dart';
import 'Screens/salesScreen.dart';
import 'Screens/services.dart';
import 'Screens/splashScreen.dart';
import 'Classes/appointment.dart';
import 'Classes/customer.dart';
import 'Classes/expense.dart';
import 'Classes/invoice.dart';
import 'Classes/serviceClass.dart';
import 'Classes/user.dart';
import 'auth/StaffAuthManagementPage.dart';
import 'auth/forgotPasswordScreen.dart';
import 'auth/loginScreen.dart';
import 'auth/signUpScreen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:awesome_notifications/awesome_notifications.dart';

void registerAdapters() {
  Hive.registerAdapter(AppointmentAdapter());
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(InvoiceAdapter());
  Hive.registerAdapter(ServiceAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(AppCategory.CategoryAdapter());
  Hive.registerAdapter(StaffAdapter());
}

Future<void> migrateAppointments() async {
  final box = await Hive.openBox<Appointment>('appointments');
  bool migrationNeeded = false;

  print('Checking appointments for migration...');
  for (var i = 0; i < box.length; i++) {
    final appointment = box.getAt(i);
    if (appointment != null) {
      print('Appointment $i: customerName=${appointment.customerName}, time=${appointment.time}, reminderTime=${appointment.reminderTime}, service=${appointment.service}, isUtc=${appointment.time.isUtc}');
      try {
        final isTimeUtc = appointment.time.isUtc;
        final isReminderTimeUtc = appointment.reminderTime != null && appointment.reminderTime!.isUtc;
        final isTimeInvalid = appointment.time.isBefore(DateTime(2000)) || appointment.time.isAfter(DateTime(2100));
        final isReminderTimeInvalid = appointment.reminderTime != null &&
            (appointment.reminderTime!.isBefore(DateTime(2000)) || appointment.reminderTime!.isAfter(DateTime(2100)));
        if (isTimeUtc || isReminderTimeUtc || isTimeInvalid || isReminderTimeInvalid) {
          migrationNeeded = true;
          break;
        }
      } catch (e) {
        print('Migration needed due to error: $e');
        migrationNeeded = true;
        break;
      }
    }
  }

  if (migrationNeeded) {
    print('Starting appointment migration...');
    try {
      final tempBox = await Hive.openBox<Appointment>('appointments_temp');
      await tempBox.clear();

      for (var i = 0; i < box.length; i++) {
        final oldAppointment = box.getAt(i);
        if (oldAppointment != null) {
          try {
            final localTime = oldAppointment.time.isUtc ? oldAppointment.time.toLocal() : oldAppointment.time;
            final isTimeInvalid = localTime.isBefore(DateTime(2000)) || localTime.isAfter(DateTime(2100));
            final localReminderTime = oldAppointment.reminderTime != null
                ? (oldAppointment.reminderTime!.isUtc
                ? oldAppointment.reminderTime!.toLocal()
                : oldAppointment.reminderTime)
                : null;
            final isReminderTimeInvalid = localReminderTime != null &&
                (localReminderTime.isBefore(DateTime(2000)) || localReminderTime.isAfter(DateTime(2100)));

            final newAppointment = Appointment(
              customerName: oldAppointment.customerName,
              time: isTimeInvalid ? DateTime.now() : localTime,
              reminderTime: isReminderTimeInvalid ? null : localReminderTime,
              service: oldAppointment.service,
              avatarPath: oldAppointment.avatarPath,
            );
            await tempBox.put(i, newAppointment);
            print('Migrated appointment $i: time=${oldAppointment.time} -> $localTime, reminderTime=${oldAppointment.reminderTime} -> $localReminderTime');
          } catch (e) {
            print('Error migrating appointment $i: $e');
            final newAppointment = Appointment(
              customerName: oldAppointment.customerName,
              time: oldAppointment.time,
              reminderTime: null,
              service: oldAppointment.service,
              avatarPath: oldAppointment.avatarPath,
            );
            await tempBox.put(i, newAppointment);
          }
        }
      }

      await box.clear();
      for (var i = 0; i < tempBox.length; i++) {
        final appointment = tempBox.getAt(i);
        if (appointment != null) {
          await box.put(i, appointment);
        }
      }

      await tempBox.clear();
      await tempBox.close();
      await Hive.deleteBoxFromDisk('appointments_temp');
      print('Migration completed successfully.');
    } catch (e) {
      print('Migration failed: $e');
    } finally {
      await box.close();
    }
  } else {
    print('No migration needed.');
    await box.close();
  }
}

Future<void> showTestNotification() async {
  try {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'appointment_channel',
        title: 'Test Notification',
        body: 'This is a test to verify notifications are working.',
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
      ),
    );
    print('Test notification shown.');
  } catch (e) {
    print('Failed to show test notification: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone
  tz.initializeTimeZones();
  final deviceTimeZone = DateTime.now().timeZoneName;
  print('Device timezone: $deviceTimeZone');
  if (deviceTimeZone == 'PKT') {
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    print('Set tz.local to Asia/Karachi for PKT');
  }
  final localTimezone = tz.local;
  print('App using device timezone: ${localTimezone.name}, offset: ${localTimezone.currentTimeZone.offset ~/ 3600000} hours');
  print('Timezone database locations: ${tz.timeZoneDatabase.locations.keys.take(10).toList()}');

  // Initialize notifications
  try {
    await NotificationService().initNotification();
    print('Notification service initialized successfully.');
    await showTestNotification();
  } catch (e) {
    print('Failed to initialize notifications: $e');
  }

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize Hive
  try {
    final dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);
    print('Hive initialized successfully.');
  } catch (e) {
    print('Failed to initialize Hive: $e');
  }

  // Register adapters
  registerAdapters();

  // Migrate appointments
  try {
    await migrateAppointments();
  } catch (e) {
    print('Appointment migration failed: $e');
  }

  // Open Hive boxes
  try {
    await Hive.openBox<Appointment>('appointments');
    await Hive.openBox<Customer>('customers');
    await Hive.openBox<Expense>('expenses');
    await Hive.openBox<Invoice>('invoices');
    await Hive.openBox<Service>('services');
    await Hive.openBox<User>('users');
    await Hive.openBox<AppCategory.Category>('categories');
    await Hive.openBox<Staff>('staff');
    print('Hive boxes opened successfully.');
  } catch (e) {
    print('Failed to open Hive boxes: $e');
  }

  // Initialize GetX controllers
  Get.put(DataController());
  Get.put(ThemeController());
  Get.put(AppointmentController());
  Get.put(AuthController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Barber Shop',
      initialRoute: '/splash',
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      getPages: [
        GetPage(name: '/splash', page: () => const Splashscreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignupScreen()),
        GetPage(name: '/forgot-password', page: () => const ForgotPasswordScreen()),
        GetPage(name: '/navbar', page: () => const AdminNavBarPage()),
        GetPage(name: '/staff-navbar', page: () => const StaffNavBarPage()),
        GetPage(name: '/invoice', page: () => const AllInvoicesScreen()),
        GetPage(name: '/dashboard', page: () => const AdminDashboard()),
        GetPage(name: '/services', page: () => const ServicesScreen()),
        GetPage(name: '/generate-invoice', page: () => const GenerateInvoiceScreen()),
        GetPage(name: '/finance', page: () => const FinancialOverviewPage()),
        GetPage(name: '/customers', page: () => CustomersScreen()),
        GetPage(name: '/all-expenses', page: () => ExpensesPage()),
        GetPage(name: '/sales', page: () => SalesPage()),
        GetPage(name: '/admin-appointments', page: () => AdminAppointmentScreen()),
        GetPage(name: '/expenses', page: () => ExpensesScreen()),
        GetPage(name: '/profile', page: () => ProfilePage()),
        GetPage(name: '/customize-app', page: () => CustomizeAppPage()),
        GetPage(name: '/staff', page: () => StaffPage()),
        GetPage(name: '/staff-management', page: () => StaffManagementScreen()),
      ],
    );
  }
}