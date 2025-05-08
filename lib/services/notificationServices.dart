import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Classes/appointment.dart';

class NotificationService {
  Future<void> initNotification() async {
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
      debug: true,
    );
    print('Awesome Notifications initialized.');
  }

  Future<void> scheduleNotification(Appointment appointment, int notificationId) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'appointment_channel',
        title: 'Appointment Reminder',
        body: '${appointment.customerName} has an appointment for ${appointment.service} at ${DateFormat('h:mm a').format(appointment.time)}',
        payload: {'name': appointment.customerName},
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar.fromDate(
        date: appointment.reminderTime ?? appointment.time.subtract(const Duration(minutes: 30)),
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
    print('Notification scheduled with Awesome Notifications for ID: $notificationId');
  }

  Future<void> clearAllNotifications() async {
    await AwesomeNotifications().cancelAll();
    print('All notifications cleared.');
  }
}