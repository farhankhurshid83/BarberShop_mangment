import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../Classes/appointment.dart';

class AppointmentController extends GetxController {
  late Box<Appointment> _appointmentBox;
  var appointments = <Appointment>[].obs;
  var filteredAppointments = <Appointment>[].obs;
  var selectedDate = DateTime.now().obs;
  var customerNameFilter = ''.obs;
  var serviceFilter = ''.obs;
  var dateRange = Rx<DateTimeRange?>(null);

  @override
  void onInit() async {
    super.onInit();
    _appointmentBox = Hive.box<Appointment>('appointments');
    await loadAppointments();
    _appointmentBox.listenable().addListener(() {
      appointments.assignAll(_appointmentBox.values);
      applyFilters();
    });
    applyFilters();
  }

  Future<void> loadAppointments() async {
    try {
      appointments.assignAll(_appointmentBox.values);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load appointments');
    }
  }

  void addAppointment(Appointment appointment) async {
    try {
      await _appointmentBox.add(appointment);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add appointment');
    }
  }

  void removeAppointment(int index) async {
    try {
      if (index >= 0 && index < _appointmentBox.length) {
        await _appointmentBox.deleteAt(index);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove appointment');
    }
  }

  // Optional: Method to remove past appointments from Hive
  Future<void> removePastAppointments() async {
    try {
      final now = DateTime.now();
      final pastAppointments = _appointmentBox.values.toList().asMap().entries.where((entry) {
        return entry.value.time.isBefore(now);
      }).toList();

      for (var entry in pastAppointments.reversed) {
        await _appointmentBox.deleteAt(entry.key);
      }
      appointments.removeWhere((appointment) => appointment.time.isBefore(now));
      applyFilters();
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove past appointments');
    }
  }

  void applyFilters() {
    filteredAppointments.value = appointments.where((appointment) {
      bool matchesCustomer = customerNameFilter.isEmpty ||
          appointment.customerName.toLowerCase().contains(customerNameFilter.value.toLowerCase());
      bool matchesService = serviceFilter.isEmpty || appointment.service == serviceFilter.value;
      bool matchesDate = dateRange.value == null ||
          (appointment.time.isAfter(dateRange.value!.start.subtract(Duration(days: 1))) &&
              appointment.time.isBefore(dateRange.value!.end.add(Duration(days: 1))));
      return matchesCustomer && matchesService && matchesDate;
    }).toList();
  }

  void setCustomerNameFilter(String name) {
    customerNameFilter.value = name;
    applyFilters();
  }

  void setServiceFilter(String service) {
    serviceFilter.value = service;
    applyFilters();
  }

  void setDateRange(DateTimeRange? range) {
    dateRange.value = range;
    applyFilters();
  }

  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  // New method to clear appointments for debugging
  Future<void> clearAppointments() async {
    try {
      await _appointmentBox.clear();
      appointments.clear();
      filteredAppointments.clear();
      Get.snackbar('Success', 'Appointments cleared');
    } catch (e) {
      Get.snackbar('Error', 'Failed to clear appointments');
    }
  }

  void logAppointments() {
    for (var appointment in _appointmentBox.values) {}
  }
}