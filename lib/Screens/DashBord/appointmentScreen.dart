import 'dart:io' show Platform;
import 'package:app_settings/app_settings.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:memory_capsule/Classes/customer.dart';
import 'dart:ui' show ImageFilter;
import '../../Classes/appointment.dart';
import '../../Controllers/appointmentController.dart';
import '../../Controllers/dataController.dart';
import 'package:memory_capsule/services/notificationServices.dart';
import 'package:timezone/timezone.dart' as tz;
import 'appointment_detail.dart';

class AdminAppointmentScreen extends StatefulWidget {
  const AdminAppointmentScreen({super.key});

  @override
  _AdminAppointmentScreenState createState() => _AdminAppointmentScreenState();
}

class _AdminAppointmentScreenState extends State<AdminAppointmentScreen> with SingleTickerProviderStateMixin {
  final AppointmentController appointmentController = Get.put(AppointmentController());
  final DataController dataController = Get.find();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _reminderTimeController = TextEditingController();
  String? _selectedService;
  late TabController _tabController;
  Customer? _selectedCustomer;
  List<Customer> _suggestedCustomers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final localTimezone = tz.local;
    print('AdminAppointmentScreen using device timezone: ${localTimezone.name}, offset: ${localTimezone.currentTimeZone.offset ~/ 3600000} hours');
    print('Device timezone: ${DateTime.now().timeZoneName}');

    // Defer async operations to after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeNotifications();
        _requestPermissions();
        promptNotificationSettings();
      }
    });
  }

  void promptNotificationSettings() {
    if (!mounted) return;
    Get.snackbar(
      'Enable Notifications',
      'To receive appointment reminders, enable notifications, disable battery optimization, allow auto-start, enable lock screen notifications, and allow alarms in Settings > Apps > Memory Capsule.',
      backgroundColor: Theme.of(context).colorScheme.primary,
      colorText: Theme.of(context).colorScheme.onPrimary,
      duration: const Duration(seconds: 10),
      mainButton: TextButton(
        onPressed: () async {
          await AppSettings.openAppSettings();
        },
        child: Text('Open Settings', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
      ),
    );
  }

  Future<void> _initializeNotifications() async {
    if (!mounted || !Platform.isAndroid) return;
    try {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'appointment_channel',
            channelName: 'Appointment Reminders',
            channelDescription: 'Notifications for upcoming appointments',
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Colors.blue,
          ),
        ],
      );
      final isInitialized = await AwesomeNotifications().isNotificationAllowed();
      print('Notification initialization status: $isInitialized');
      if (!isInitialized) {
        Get.snackbar(
          'Warning',
          'Notifications are not allowed. Please enable in Settings > Apps > Memory Capsule > Notifications.',
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError,
          duration: const Duration(seconds: 7),
        );
      } else {
        print('Appointment channel ready.');
      }
    } catch (e) {
      print('Failed to initialize notifications: $e');
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to initialize notifications: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError,
          duration: const Duration(seconds: 7),
        );
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (!mounted || !Platform.isAndroid) return;
    try {
      final notificationStatus = await AwesomeNotifications().requestPermissionToSendNotifications();
      print('Notification permission: $notificationStatus');
      if (!notificationStatus) {
        Get.snackbar(
          'Warning',
          'Notification permission is required. Enable it in Settings > Apps > Memory Capsule > Notifications.',
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError,
          duration: const Duration(seconds: 7),
        );
      }

      await AppSettings.openAppSettings();
      Get.snackbar(
        'Battery Optimization',
        'Please disable battery optimization for Memory Capsule to ensure timely notifications.',
        backgroundColor: Theme.of(context).colorScheme.primary,
        colorText: Theme.of(context).colorScheme.onPrimary,
        duration: const Duration(seconds: 7),
      );
    } catch (e) {
      print('Error requesting permissions: $e');
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to request permissions: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  Future<void> _scheduleNotification(Appointment appointment, int notificationId) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final localTimezone = tz.local;
      print('Scheduling notification: ${appointment.customerName}, ID: $notificationId, reminderTime: ${appointment.reminderTime}, appointmentTime: ${appointment.time}, current time: $now, timezone: ${localTimezone.name}, offset: ${localTimezone.currentTimeZone.offset ~/ 3600000} hours');
      print('Input appointment time: ${appointment.time}, isUtc: ${appointment.time.isUtc}');
      print('Input reminder time: ${appointment.reminderTime}, isUtc: ${appointment.reminderTime?.isUtc}');

      final reminderTime = appointment.reminderTime ?? appointment.time.subtract(const Duration(minutes: 30));
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);
      print('Converted reminderTime to TZDateTime: $scheduledDate');

      // Validate scheduled date
      if (scheduledDate.isBefore(now) || scheduledDate.year < 2000 || scheduledDate.year > 2100) {
        print('Invalid scheduled date: $scheduledDate');
        if (mounted) {
          Get.snackbar(
            'Notification Error',
            'Invalid reminder time. Please set a future date.',
            backgroundColor: Theme.of(context).colorScheme.error,
            colorText: Theme.of(context).colorScheme.onError,
            duration: const Duration(seconds: 5),
          );
        }
        return;
      }

      if (scheduledDate.isBefore(now.add(const Duration(seconds: 5))) || scheduledDate.isAtSameMomentAs(now)) {
        print('Warning: Scheduled time ($scheduledDate) is too close to now ($now). Showing immediate notification.');
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationId,
            channelKey: 'appointment_channel',
            title: 'Appointment Reminder',
            body: '${appointment.customerName} has an appointment for ${appointment.service} at ${DateFormat('h:mm a').format(appointment.time)}',
            payload: {'name': appointment.customerName},
            category: NotificationCategory.Reminder,
            notificationLayout: NotificationLayout.Default,
          ),
        );
        print('Immediate notification shown for ID: $notificationId');
        if (mounted) {
          Get.snackbar(
            'Notification',
            'Immediate reminder sent for ${appointment.customerName}. Check notification shade.',
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            colorText: Theme.of(context).colorScheme.onPrimary,
            duration: const Duration(seconds: 5),
          );
        }
      } else {
        print('Attempting to schedule notification for $scheduledDate (ID: $notificationId)');
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationId,
            channelKey: 'appointment_channel',
            title: 'Appointment Reminder',
            body: '${appointment.customerName} has an appointment for ${appointment.service} at ${DateFormat('h:mm a').format(appointment.time)}',
            payload: {'name': appointment.customerName},
            category: NotificationCategory.Reminder,
            notificationLayout: NotificationLayout.Default,
          ),
          schedule: NotificationCalendar.fromDate(
            date: scheduledDate.toLocal(),
            preciseAlarm: true,
            allowWhileIdle: true,
          ),
        );
        print('Notification scheduled successfully for $scheduledDate (ID: $notificationId)');
        if (mounted) {
          Get.snackbar(
            'Notification',
            'Reminder scheduled for ${appointment.customerName} at ${DateFormat('h:mm a').format(reminderTime)}. Set reminders at least 10 minutes in the future and wait until ${DateFormat('h:mm a').format(reminderTime)} to confirm.',
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            colorText: Theme.of(context).colorScheme.onPrimary,
            duration: const Duration(seconds: 7),
          );
        }
      }
    } catch (e) {
      print('Failed to schedule notification: $e');
      if (mounted) {
        Get.snackbar(
          'Notification Error',
          'Failed to schedule notification: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  Future<void> _showTestNotification() async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 999,
          channelKey: 'appointment_channel',
          title: 'Test Notification',
          body: 'This is a test notification to verify the system.',
          payload: {'type': 'test_notification'},
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.Default,
          autoDismissible: true,
        ),
      );
      print('Test notification shown.');
      if (mounted) {
        Get.snackbar(
          'Success',
          'Test notification sent. If not visible, check Settings > Apps > Memory Capsule > Notifications.',
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          colorText: Theme.of(context).colorScheme.onPrimary,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      print('Failed to show test notification: $e');
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to show test notification: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _reminderTimeController.dispose();
    super.dispose();
  }

  void _onCustomerNameChanged(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      setState(() {
        _selectedCustomer = null;
        _suggestedCustomers = dataController.customers.toList();
      });
      return;
    }

    final filteredCustomers = dataController.customers
        .where((customer) => customer.name.toLowerCase().contains(name.toLowerCase()))
        .toList();

    setState(() {
      _suggestedCustomers = filteredCustomers;
      _selectedCustomer = filteredCustomers.firstWhereOrNull(
            (customer) => customer.name.toLowerCase() == name.toLowerCase(),
      );
    });
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _nameController.text = customer.name;
      _suggestedCustomers = [];
    });
  }

  Future<void> _showAddCustomerDetailsDialog(String name) async {
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add Customer",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, _, __) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            scrollable: true,
            title: Text(
              'New Customer: $name',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'e.g., +1234567890',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          keyboardType: TextInputType.phone,
                          maxLength: 15,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address (Optional)',
                            hintText: 'e.g., example@domain.com',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          maxLength: 50,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              GestureDetector(
                onTapDown: (_) => HapticFeedback.lightImpact(),
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    setState(() => isLoading = true);
                    HapticFeedback.lightImpact();
                    final phone = phoneController.text.trim();
                    final email = emailController.text.trim();
                    if (phone.isNotEmpty) {
                      final newCustomer = Customer(
                        name: name,
                        phone: phone,
                        email: email.isNotEmpty ? email : null,
                      );
                      await Future.microtask(() => dataController.addCustomer(newCustomer));
                      Navigator.pop(context);
                      setState(() {
                        _selectedCustomer = newCustomer;
                        _nameController.text = newCustomer.name;
                      });
                    } else {
                      Get.snackbar('Error', 'Phone number is required');
                    }
                    setState(() => isLoading = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onTertiary,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Add Customer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddAppointmentDialog(BuildContext context) async {
    _nameController.clear();
    _dateController.clear();
    _timeController.clear();
    _reminderTimeController.clear();
    _selectedService = null;
    _selectedCustomer = null;
    _suggestedCustomers = [];
    final FocusNode nameFocus = FocusNode();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          scrollable: true,
          title: Text(
            'Add Appointment',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, dialogSetState) {
              nameFocus.addListener(() {
                if (nameFocus.hasFocus && _nameController.text.trim().isEmpty) {
                  dialogSetState(() {
                    _suggestedCustomers = dataController.customers.toList();
                  });
                }
              });

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    focusNode: nameFocus,
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      hintText: 'e.g., John Doe',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _selectedCustomer != null
                          ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                          : null,
                    ),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    onChanged: (value) {
                      _onCustomerNameChanged(value);
                      dialogSetState(() {});
                    },
                    onTap: () {
                      if (_nameController.text.trim().isEmpty) {
                        dialogSetState(() {
                          _suggestedCustomers = dataController.customers.toList();
                        });
                      }
                    },
                  ),
                  if (_suggestedCustomers.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _suggestedCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _suggestedCustomers[index];
                          return ListTile(
                            title: Text(
                              customer.name,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              customer.email ?? 'No email provided',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            onTap: () {
                              _selectCustomer(customer);
                              dialogSetState(() {});
                            },
                          );
                        },
                        separatorBuilder: (context, index) => Divider(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          thickness: 1.0,
                          height: 1,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedService,
                    decoration: InputDecoration(
                      labelText: 'Service',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: dataController.services.map((service) {
                      return DropdownMenuItem<String>(
                        value: service.name,
                        child: Text(service.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      dialogSetState(() => _selectedService = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      hintText: 'Select date',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null) {
                        dialogSetState(() {
                          _dateController.text = DateFormat('MMMM d, yyyy').format(pickedDate);
                        });
                      }
                    },
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: 'Appointment Time',
                      hintText: 'Select time',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        final now = DateTime.now();
                        final dateTime = DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
                        dialogSetState(() {
                          _timeController.text = DateFormat('h:mm a').format(dateTime);
                        });
                      }
                    },
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reminderTimeController,
                    decoration: InputDecoration(
                      labelText: 'Reminder Time',
                      hintText: 'Select reminder time',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      if (_dateController.text.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Please select an appointment date first',
                          backgroundColor: Theme.of(context).colorScheme.error,
                          colorText: Theme.of(context).colorScheme.onError,
                        );
                        return;
                      }
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        final date = DateFormat('MMMM d, yyyy').parse(_dateController.text);
                        final dateTime = DateTime(date.year, date.month, date.day, pickedTime.hour, pickedTime.minute);
                        dialogSetState(() {
                          _reminderTimeController.text = DateFormat('h:mm a').format(dateTime);
                        });
                      }
                    },
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameFocus.dispose();
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty &&
                    _selectedService != null &&
                    _dateController.text.isNotEmpty &&
                    _timeController.text.isNotEmpty) {
                  final date = DateFormat('MMMM d, yyyy').parse(_dateController.text);
                  final timeParts = _timeController.text.split(' ');
                  final time = DateFormat('h:mm a').parse('${timeParts[0]} ${timeParts[1]}');
                  final appointmentTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  DateTime? reminderDateTime;
                  if (_reminderTimeController.text.isNotEmpty) {
                    final reminderTimeParts = _reminderTimeController.text.split(' ');
                    final reminderTime = DateFormat('h:mm a').parse('${reminderTimeParts[0]} ${reminderTimeParts[1]}');
                    reminderDateTime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      reminderTime.hour,
                      reminderTime.minute,
                    );
                  }

                  // Validate times
                  if (appointmentTime.isBefore(DateTime.now())) {
                    Get.snackbar(
                      'Error',
                      'Appointment time must be in the future',
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
                    );
                    return;
                  }
                  if (reminderDateTime != null && reminderDateTime.isAfter(appointmentTime)) {
                    Get.snackbar(
                      'Error',
                      'Reminder time must be before or at the appointment time',
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
                    );
                    return;
                  }
                  if (reminderDateTime != null && reminderDateTime.isBefore(DateTime.now())) {
                    Get.snackbar(
                      'Error',
                      'Reminder time must be in the future',
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
                    );
                    return;
                  }

                  if (_selectedCustomer == null) {
                    final name = _nameController.text.trim();
                    final existingCustomer = dataController.customers
                        .firstWhereOrNull((customer) => customer.name.toLowerCase() == name.toLowerCase());
                    if (existingCustomer == null) {
                      Navigator.pop(context);
                      nameFocus.dispose();
                      await _showAddCustomerDetailsDialog(name);
                      if (_selectedCustomer == null) return;
                    } else {
                      _selectedCustomer = existingCustomer;
                    }
                  }
                  final newAppointment = Appointment(
                    customerName: _selectedCustomer!.name,
                    time: appointmentTime,
                    reminderTime: reminderDateTime,
                    service: _selectedService!,
                    avatarPath: 'assets/images/customer.png',
                  );
                  await Future.microtask(() => appointmentController.addAppointment(newAppointment));
                  final notificationId = DateTime.now().millisecondsSinceEpoch % 1000000;
                  await _scheduleNotification(newAppointment, notificationId);
                  nameFocus.dispose();
                  Navigator.pop(context);
                  Get.snackbar(
                    'Success',
                    'Appointment added and notification scheduled.',
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    colorText: Theme.of(context).colorScheme.onPrimary,
                    duration: const Duration(seconds: 5),
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Please fill in all required fields',
                    backgroundColor: Theme.of(context).colorScheme.error,
                    colorText: Theme.of(context).colorScheme.onError,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Add',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditAppointmentDialog(BuildContext context, Appointment appointment, int index) async {
    _nameController.text = appointment.customerName;
    _dateController.text = DateFormat('MMMM d, yyyy').format(appointment.time);
    _timeController.text = DateFormat('h:mm a').format(appointment.time);
    _reminderTimeController.text = appointment.reminderTime != null
        ? DateFormat('h:mm a').format(appointment.reminderTime!)
        : '';
    _selectedService = appointment.service;
    _selectedCustomer = dataController.customers.firstWhereOrNull(
          (customer) => customer.name.toLowerCase() == appointment.customerName.toLowerCase(),
    );
    _suggestedCustomers = [];
    final FocusNode nameFocus = FocusNode();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          scrollable: true,
          title: Text(
            'Edit Appointment',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, dialogSetState) {
              nameFocus.addListener(() {
                if (nameFocus.hasFocus && _nameController.text.trim().isEmpty) {
                  dialogSetState(() {
                    _suggestedCustomers = dataController.customers.toList();
                  });
                }
              });

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    focusNode: nameFocus,
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      hintText: 'e.g., John Doe',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _selectedCustomer != null
                          ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                          : null,
                    ),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    onChanged: (value) {
                      _onCustomerNameChanged(value);
                      dialogSetState(() {});
                    },
                    onTap: () {
                      if (_nameController.text.trim().isEmpty) {
                        dialogSetState(() {
                          _suggestedCustomers = dataController.customers.toList();
                        });
                      }
                    },
                  ),
                  if (_suggestedCustomers.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _suggestedCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _suggestedCustomers[index];
                          return ListTile(
                            title: Text(
                              customer.name,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              customer.email ?? 'No email provided',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            onTap: () {
                              _selectCustomer(customer);
                              dialogSetState(() {});
                            },
                          );
                        },
                        separatorBuilder: (context, index) => Divider(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          thickness: 1.0,
                          height: 1,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedService,
                    decoration: InputDecoration(
                      labelText: 'Service',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: dataController.services.map((service) {
                      return DropdownMenuItem<String>(
                        value: service.name,
                        child: Text(service.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      dialogSetState(() => _selectedService = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      hintText: 'Select date',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null) {
                        dialogSetState(() {
                          _dateController.text = DateFormat('MMMM d, yyyy').format(pickedDate);
                        });
                      }
                    },
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: 'Appointment Time',
                      hintText: 'Select time',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        final now = DateTime.now();
                        final dateTime = DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
                        dialogSetState(() {
                          _timeController.text = DateFormat('h:mm a').format(dateTime);
                        });
                      }
                    },
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reminderTimeController,
                    decoration: InputDecoration(
                      labelText: 'Reminder Time',
                      hintText: 'Select reminder time',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    readOnly: true,
                    onTap: () async {
                      if (_dateController.text.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Please select an appointment date first',
                          backgroundColor: Theme.of(context).colorScheme.error,
                          colorText: Theme.of(context).colorScheme.onError,
                        );
                        return;
                      }
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        final date = DateFormat('MMMM d, yyyy').parse(_dateController.text);
                        final dateTime = DateTime(date.year, date.month, date.day, pickedTime.hour, pickedTime.minute);
                        dialogSetState(() {
                          _reminderTimeController.text = DateFormat('h:mm a').format(dateTime);
                        });
                      }
                    },
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameFocus.dispose();
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty &&
                    _selectedService != null &&
                    _dateController.text.isNotEmpty &&
                    _timeController.text.isNotEmpty) {
                  final date = DateFormat('MMMM d, yyyy').parse(_dateController.text);
                  final timeParts = _timeController.text.split(' ');
                  final time = DateFormat('h:mm a').parse('${timeParts[0]} ${timeParts[1]}');
                  final appointmentTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  DateTime? reminderDateTime;
                  if (_reminderTimeController.text.isNotEmpty) {
                    final reminderTimeParts = _reminderTimeController.text.split(' ');
                    final reminderTime = DateFormat('h:mm a').parse('${reminderTimeParts[0]} ${reminderTimeParts[1]}');
                    reminderDateTime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      reminderTime.hour,
                      reminderTime.minute,
                    );
                  }

                  // Validate times
                  if (appointmentTime.isBefore(DateTime.now())) {
                    Get.snackbar(
                      'Error',
                      'Appointment time must be in the future',
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
                    );
                    return;
                  }
                  if (reminderDateTime != null && reminderDateTime.isAfter(appointmentTime)) {
                    Get.snackbar(
                      'Error',
                      'Reminder time must be before or at the appointment time',
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
                    );
                    return;
                  }
                  if (reminderDateTime != null && reminderDateTime.isBefore(DateTime.now())) {
                    Get.snackbar(
                      'Error',
                      'Reminder time must be in the future',
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
                    );
                    return;
                  }

                  if (_selectedCustomer == null) {
                    final name = _nameController.text.trim();
                    final existingCustomer = dataController.customers
                        .firstWhereOrNull((customer) => customer.name.toLowerCase() == name.toLowerCase());
                    if (existingCustomer == null) {
                      Navigator.pop(context);
                      nameFocus.dispose();
                      await _showAddCustomerDetailsDialog(name);
                      if (_selectedCustomer == null) return;
                    } else {
                      _selectedCustomer = existingCustomer;
                    }
                  }
                  await Future.microtask(() => appointmentController.removeAppointment(index));
                  await AwesomeNotifications().cancel(index);
                  final updatedAppointment = Appointment(
                    customerName: _selectedCustomer!.name,
                    time: appointmentTime,
                    reminderTime: reminderDateTime,
                    service: _selectedService!,
                    avatarPath: 'assets/images/customer.png',
                  );
                  await Future.microtask(() => appointmentController.addAppointment(updatedAppointment));
                  final notificationId = DateTime.now().millisecondsSinceEpoch % 1000000;
                  await _scheduleNotification(updatedAppointment, notificationId);
                  nameFocus.dispose();
                  Navigator.pop(context);
                  Get.snackbar(
                    'Success',
                    'Appointment updated and notification scheduled.',
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    colorText: Theme.of(context).colorScheme.onPrimary,
                    duration: const Duration(seconds: 5),
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Please fill in all required fields',
                    backgroundColor: Theme.of(context).colorScheme.error,
                    colorText: Theme.of(context).colorScheme.onError,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context, Appointment appointment) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Delete Appointment',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Are you sure you want to delete the appointment for ${appointment.customerName} at ${DateFormat('h:mm a').format(appointment.time)}?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    final nameController = TextEditingController(text: appointmentController.customerNameFilter.value);
    String? selectedService = appointmentController.serviceFilter.value.isEmpty ? null : appointmentController.serviceFilter.value;
    DateTimeRange? dateRange = appointmentController.dateRange.value;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Filter Appointments',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      hintText: 'e.g., John',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedService,
                    decoration: InputDecoration(
                      labelText: 'Service',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Services', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      ),
                      ...dataController.services.map((service) {
                        return DropdownMenuItem<String>(
                          value: service.name,
                          child: Text(service.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => selectedService = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      DateTimeRange? pickedRange = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                        initialDateRange: dateRange,
                      );
                      setState(() => dateRange = pickedRange);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onTertiary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      dateRange == null ? 'Select Date Range' : 'Change Date Range',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (dateRange != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('MMM d, yyyy').format(dateRange!.start)} - ${DateFormat('MMM d, yyyy').format(dateRange!.end)}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                appointmentController.setCustomerNameFilter('');
                appointmentController.setServiceFilter('');
                appointmentController.setDateRange(null);
                Navigator.pop(context);
              },
              child: Text(
                'Clear',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                appointmentController.setCustomerNameFilter(nameController.text);
                appointmentController.setServiceFilter(selectedService ?? '');
                appointmentController.setDateRange(dateRange);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Apply',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Book Client',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_active,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _showTestNotification,
            tooltip: 'Test Notification',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.onSurface,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              indicatorColor: Theme.of(context).colorScheme.secondary,
              tabs: const [
                Tab(text: 'Calendar'),
                Tab(text: 'List'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Calendar Tab
                  Obx(() {
                    final events = <DateTime, List<Appointment>>{};
                    final futureAppointments = appointmentController.appointments
                        .where((appointment) => appointment.time.isAfter(DateTime.now()))
                        .toList();
                    for (var appointment in futureAppointments) {
                      final date = DateTime(appointment.time.year, appointment.time.month, appointment.time.day);
                      events[date] = events[date] ?? [];
                      events[date]!.add(appointment);
                    }
                    return Column(
                      children: [
                        Card(
                          color: Theme.of(context).colorScheme.secondary,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: TableCalendar(
                            firstDay: DateTime.now(),
                            lastDay: DateTime(2030),
                            focusedDay: appointmentController.selectedDate.value,
                            selectedDayPredicate: (day) => isSameDay(day, appointmentController.selectedDate.value),
                            onDaySelected: (selectedDay, focusedDay) {
                              appointmentController.setSelectedDate(selectedDay);
                            },
                            eventLoader: (day) {
                              return events[DateTime(day.year, day.month, day.day)] ?? [];
                            },
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onTertiary,
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                              defaultTextStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              weekendTextStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              outsideTextStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              todayTextStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              selectedTextStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                if (events.isNotEmpty) {
                                  return Positioned(
                                    right: 1,
                                    bottom: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      width: 20.0,
                                      height: 20.0,
                                      child: Center(
                                        child: Text(
                                          '${events.length}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return null;
                              },
                              dowBuilder: (context, day) {
                                return Center(
                                  child: Text(
                                    DateFormat.E().format(day),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onTertiary,
                                    ),
                                  ),
                                );
                              },
                            ),
                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              titleTextStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onTertiary,
                                fontWeight: FontWeight.bold,
                              ),
                              leftChevronIcon: Icon(
                                Icons.chevron_left,
                                color: Theme.of(context).colorScheme.onTertiary,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right,
                                color: Theme.of(context).colorScheme.onTertiary,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Obx(() {
                            final selectedAppointments = appointmentController.appointments
                                .where((appointment) =>
                            isSameDay(appointment.time, appointmentController.selectedDate.value) &&
                                appointment.time.isAfter(DateTime.now()))
                                .toList();
                            if (selectedAppointments.isEmpty) {
                              return Center(
                                child: Text(
                                  'No upcoming appointments for this date',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: selectedAppointments.length,
                              itemBuilder: (context, index) {
                                final appointment = selectedAppointments[index];
                                final appointmentIndex = appointmentController.appointments.indexOf(appointment);
                                return Card(
                                  color: Theme.of(context).colorScheme.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.surface,
                                      radius: 24.0,
                                      foregroundImage: appointment.avatarPath != null
                                          ? AssetImage(appointment.avatarPath!)
                                          : null,
                                      child: appointment.avatarPath == null
                                          ? Icon(
                                        Icons.person,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      )
                                          : null,
                                      onForegroundImageError: (exception, stackTrace) {},
                                    ),
                                    title: Text(
                                      appointment.customerName,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onTertiary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${DateFormat('h:mm a').format(appointment.time)} • ${appointment.service}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onTertiary,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Theme.of(context).colorScheme.onSurface,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            if (appointmentIndex != -1) {
                                              _showEditAppointmentDialog(context, appointment, appointmentIndex);
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Theme.of(context).colorScheme.error,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            if (appointmentIndex != -1) {
                                              final confirm = await _showDeleteConfirmationDialog(context, appointment);
                                              if (confirm) {
                                                await Future.microtask(
                                                      () => appointmentController.removeAppointment(appointmentIndex),
                                                );
                                                await AwesomeNotifications().cancel(appointmentIndex);
                                                Get.snackbar(
                                                  'Success',
                                                  'Appointment deleted',
                                                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                                  colorText: Theme.of(context).colorScheme.onPrimary,
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Get.to(
                                            () => AppointmentDetailScreen(
                                          appointment: appointment,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    );
                  }),
                  // List Tab
                  Obx(() {
                    final futureAppointments = appointmentController.appointments
                        .where((appointment) => appointment.time.isAfter(DateTime.now()))
                        .toList();
                    if (futureAppointments.isEmpty) {
                      return Center(
                        child: Text(
                          'No upcoming appointments',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: futureAppointments.length,
                      itemBuilder: (context, index) {
                        final appointment = futureAppointments[index];
                        final appointmentIndex = appointmentController.appointments.indexOf(appointment);
                        return Card(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              radius: 24.0,
                              foregroundImage: appointment.avatarPath != null
                                  ? AssetImage(appointment.avatarPath!)
                                  : null,
                              child: appointment.avatarPath == null
                                  ? Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.onSurface,
                              )
                                  : null,
                              onForegroundImageError: (exception, stackTrace) {},
                            ),
                            title: Text(
                              appointment.customerName,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onTertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${DateFormat('MMM d, yyyy, h:mm a').format(appointment.time)} • ${appointment.service}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onTertiary,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    if (appointmentIndex != -1) {
                                      _showEditAppointmentDialog(context, appointment, appointmentIndex);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    if (appointmentIndex != -1) {
                                      final confirm = await _showDeleteConfirmationDialog(context, appointment);
                                      if (confirm) {
                                        await Future.microtask(
                                              () => appointmentController.removeAppointment(appointmentIndex),
                                        );
                                        await AwesomeNotifications().cancel(appointmentIndex);
                                        Get.snackbar(
                                          'Success',
                                          'Appointment deleted',
                                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                          colorText: Theme.of(context).colorScheme.onPrimary,
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              Get.to(
                                    () => AppointmentDetailScreen(
                                  appointment: appointment,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: () => _showAddAppointmentDialog(context),
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onTertiary),
      ),
    );
  }
}