import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../Classes/customer.dart';
import '../Classes/expense.dart';
import '../Classes/invoice.dart';
import '../Classes/serviceClass.dart';
import '../Classes/category.dart';
import '../Classes/staff.dart';

class DataController extends GetxController {
  late Box<Service> _servicesBox;
  late Box<Customer> _customersBox;
  late Box<Invoice> _invoicesBox;
  late Box<Expense> _expensesBox;
  late Box<Category> _categoriesBox;
  late Box<Staff> _staffBox;
  var services = <Service>[].obs;
  var customers = <Customer>[].obs;
  var invoices = <Invoice>[].obs;
  var expenses = <Expense>[].obs;
  var categories = <Category>[].obs;
  var staff = <Staff>[].obs;

  @override
  void onInit() async {
    super.onInit();
    _servicesBox = Hive.box<Service>('services');
    _customersBox = Hive.box<Customer>('customers');
    _invoicesBox = Hive.box<Invoice>('invoices');
    _expensesBox = Hive.box<Expense>('expenses');
    _categoriesBox = Hive.box<Category>('categories');
    _staffBox = Hive.box<Staff>('staff');

    await loadData();
    await _initializeSampleData();

    _servicesBox.listenable().addListener(() {
      services.assignAll(_servicesBox.values);
      services.refresh();
    });
    _customersBox.listenable().addListener(() {
      customers.assignAll(_customersBox.values);
      customers.refresh();
    });
    _invoicesBox.listenable().addListener(() {
      invoices.assignAll(_invoicesBox.values);
      invoices.refresh();
    });
    _expensesBox.listenable().addListener(() {
      expenses.assignAll(_expensesBox.values);
      expenses.refresh();
    });
    _categoriesBox.listenable().addListener(() {
      categories.assignAll(_categoriesBox.values);
      categories.refresh();
    });
    _staffBox.listenable().addListener(() {
      staff.assignAll(_staffBox.values);
      staff.refresh();
    });
  }

  Future<void> loadData() async {
    try {
      services.assignAll(_servicesBox.values);
      customers.assignAll(_customersBox.values);
      invoices.assignAll(_invoicesBox.values);
      expenses.assignAll(_expensesBox.values);
      categories.assignAll(_categoriesBox.values);
      staff.assignAll(_staffBox.values);
    } catch (e) {}
  }

  Future<void> _initializeSampleData() async {
    try {
      if (_categoriesBox.isEmpty) {
        await _categoriesBox.addAll([
          Category(name: 'Haircut', imagePath: 'assets/images/haircut.jpg', isAsset: true),
          Category(name: 'Beard Trim', imagePath: 'assets/images/beardtrim.jpg', isAsset: true),
          Category(name: 'Shave', imagePath: 'assets/images/customer.png', isAsset: true),
          Category(name: 'Hair Wash', imagePath: 'assets/images/hairwash.jpg', isAsset: true),
          Category(name: 'Facial', imagePath: 'assets/images/facial.jpg', isAsset: true),
          Category(name: 'Offers', imagePath: 'assets/images/offer.jpg', isAsset: true),
        ]);
      }

      if (_servicesBox.isEmpty) {
        await _servicesBox.addAll([
          Service(
            name: "Haircut",
            price: 20.0,
            category: "Haircut",
            icon: Icons.content_cut,
            imagePath: 'assets/images/haircut.jpg',
            isAsset: true,
          ),
          Service(
            name: "Beard Trim",
            price: 10.0,
            category: "Beard Trim",
            icon: Icons.face_retouching_natural,
            imagePath: 'assets/images/beardtrim.jpg',
            isAsset: true,
          ),
          Service(
            name: "Shave",
            price: 15.0,
            category: "Shave",
            icon: Icons.account_circle_outlined,
            imagePath: 'assets/images/shave.jpg',
            isAsset: true,
          ),
          Service(
            name: "Hair Wash",
            price: 5.0,
            category: "Hair Wash",
            icon: Icons.bubble_chart,
            imagePath: 'assets/images/hairwash.jpg',
            isAsset: true,
          ),
          Service(
            name: "Facial",
            price: 25.0,
            category: "Facial",
            icon: Icons.spa,
            imagePath: 'assets/images/facial.jpg',
            isAsset: true,
          ),
          Service(
            name: "Discounted Service",
            price: 15.0,
            category: "Offers",
            icon: Icons.local_offer,
            imagePath: 'assets/images/offer.jpg',
            isAsset: true,
          ),
        ]);
      }

    } catch (e) {}
  }

  void addCustomer(Customer customer) async {
    try {
      await _customersBox.add(customer);
      customers.assignAll(_customersBox.values);
      customers.refresh();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add customer');
    }
  }

  void addInvoice(Invoice invoice) async {
    try {
      await _invoicesBox.add(invoice);
      invoices.assignAll(_invoicesBox.values);
      invoices.refresh();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add invoice');
    }
  }

  void addService(Service service) async {
    try {
      await _servicesBox.add(service);
      services.assignAll(_servicesBox.values);
      services.refresh();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add service');
    }
  }

  void addCategory(String name, String imagePath, bool isAsset) async {
    try {
      if (name.isNotEmpty) {
        final category = Category(name: name, imagePath: imagePath, isAsset: isAsset);
        await _categoriesBox.add(category);
        categories.assignAll(_categoriesBox.values);
        categories.refresh();
      } else {
        Get.snackbar('Error', 'Category name cannot be empty');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add category');
    }
  }

  void removeCategory(String name) async {
    try {
      final hasServices = services.any((service) => service.category == name);
      if (hasServices) {
        Get.snackbar(
          'Error',
          'Cannot delete category "$name" because it contains services.',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }
      final index = _categoriesBox.values.toList().indexWhere((cat) => cat.name == name);
      if (index != -1) {
        await _categoriesBox.deleteAt(index);
        categories.assignAll(_categoriesBox.values);
        categories.refresh();
      } else {
        Get.snackbar('Error', 'Category "$name" not found');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove category');
    }
  }

  void addExpense(Expense expense) async {
    try {
      await _expensesBox.add(expense);
      expenses.assignAll(_expensesBox.values);
      expenses.refresh();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add expense');
    }
  }

  void addStaff(Staff staffMember) async {
    try {
      if (staff.any((s) => s.name == staffMember.name)) {
        Get.snackbar('Error', 'Staff with this name already exists');
        return;
      }
      await _staffBox.add(staffMember);
      staff.assignAll(_staffBox.values);
      staff.refresh();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add staff');
    }
  }

  void updateStaff(Staff staffMember) async {
    try {
      final index = _staffBox.values.toList().indexWhere((s) => s.name == staffMember.name);
      if (index != -1) {
        await _staffBox.putAt(index, staffMember);
        staff.assignAll(_staffBox.values);
        staff.refresh();
      } else {
        Get.snackbar('Error', 'Staff not found');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update staff');
    }
  }

  void removeStaff(String name) async {
    try {
      final index = _staffBox.values.toList().indexWhere((s) => s.name == name);
      if (index != -1) {
        await _staffBox.deleteAt(index);
        staff.assignAll(_staffBox.values);
        staff.refresh();
      } else {
        Get.snackbar('Error', 'Staff not found');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove staff');
    }
  }

  void removeCustomer(String name) async {
    try {
      final index = _customersBox.values.toList().indexWhere((customer) => customer.name == name);
      if (index != -1) {
        await _customersBox.deleteAt(index);
        customers.assignAll(_customersBox.values);
        customers.refresh();
      } else {
        Get.snackbar('Error', 'Customer "$name" not found');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove customer');
    }
  }

  void removeExpense(int expenseId) async {
    try {
      final index = _expensesBox.values.toList().indexWhere((expense) => expense.id.toString() == expenseId.toString());
      if (index != -1) {
        await _expensesBox.deleteAt(index);
        expenses.removeWhere((expense) => expense.id.toString() == expenseId.toString());
        expenses.refresh();
      } else {
        Get.snackbar('Error', 'Expense not found');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove expense');
    }
  }

  void removeInvoice(String invoiceId) {
    invoices.removeWhere((invoice) => invoice.id == invoiceId);
    invoices.refresh();
  }

  void removeService(int index) async {
    try {
      await _servicesBox.deleteAt(index);
      services.assignAll(_servicesBox.values);
      services.refresh();
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove service');
    }
  }

  void updateExpense(int expenseId, Expense updatedExpense) {
    final index = expenses.indexWhere((expense) => expense.id.toString() == expenseId.toString());
    if (index != -1) {
      expenses[index] = updatedExpense;
      expenses.refresh();
    }
  }

  void updateService(int index, Service updatedService) async {
    try {
      if (index >= 0 && index < _servicesBox.length) {
        await _servicesBox.putAt(index, updatedService);
        services.assignAll(_servicesBox.values);
        services.refresh();
      } else {
        Get.snackbar('Error', 'Invalid service index');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update service');
    }
  }

  void updateCustomer(Customer customer) async {
    try {
      final index = _customersBox.values.toList().indexWhere((c) => c.name == customer.name);
      if (index != -1) {
        await _customersBox.putAt(index, customer);
        customers.assignAll(_customersBox.values);
        customers.refresh();
      } else {
        Get.snackbar('Error', 'Customer not found');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update customer');
    }
  }

  void logBoxContents() {
    for (var service in _servicesBox.values) {}
    for (var customer in _customersBox.values) {}
    for (var invoice in _invoicesBox.values) {}
    for (var expense in _expensesBox.values) {}
    for (var category in _categoriesBox.values) {}
    for (var staffMember in _staffBox.values) {}
  }

  void resetData() async {
    try {
      await _servicesBox.clear();
      await _customersBox.clear();
      await _invoicesBox.clear();
      await _expensesBox.clear();
      await _categoriesBox.clear();
      await _staffBox.clear();
      await _initializeSampleData();
      await loadData();
    } catch (e) {
      Get.snackbar('Error', 'Failed to reset data');
    }
  }
}