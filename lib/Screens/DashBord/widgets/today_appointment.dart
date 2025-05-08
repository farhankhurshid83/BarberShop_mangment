import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../Controllers/appointmentController.dart';
import '../appointment_detail.dart';

class UpcomingAppointmentsWidget extends StatelessWidget {
  const UpcomingAppointmentsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AppointmentController appointmentController = Get.find<AppointmentController>();

    return Obx(() {
      // Get the current time
      final now = DateTime.now();

      // Filter appointments to only include upcoming ones (time is after now)
      // Then sort by time (nearest first) and limit to 2
      final upcomingAppointments = appointmentController.appointments
          .where((appointment) => appointment.time.isAfter(now))
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      final displayAppointments = upcomingAppointments.take(2).toList();

      return Card(
        color: Theme.of(context).colorScheme.secondary,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Upcoming Appointments",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onTertiary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${upcomingAppointments.length} Total',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (displayAppointments.isEmpty)
                Column(
                  children: [
                    Center(
                      child: Text(
                        'No upcoming appointments.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Get.toNamed('/admin-appointments');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'SCHEDULE AN APPOINTMENT',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                ...displayAppointments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final appointment = entry.value;
                  return Column(
                    children: [
                      ListTile(
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
                          DateFormat('d MMM h:mm a').format(appointment.time),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Text(
                          appointment.service,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onTertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onTap: () {
                          Get.to(() => AppointmentDetailScreen(appointment: appointment));
                        },
                      ),
                      if (index < displayAppointments.length - 1)
                        Divider(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                    ],
                  );
                }),
              if (upcomingAppointments.isNotEmpty) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Get.toNamed('/admin-appointments');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'VIEW ALL APPOINTMENTS',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}