import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../Classes/user.dart';
import 'appointmentController.dart';
import 'dataController.dart';

class AuthController extends GetxController {
  late Box<User> _userBox;
  var isLoggedIn = false.obs;
  var currentUser = Rxn<User>();
  var isLoading = false.obs;

  @override
  void onInit() async {
    super.onInit();
    _userBox = Hive.box<User>('users');
    final loggedInUser = _userBox.values.firstWhereOrNull((user) => user.isLoggedIn == true);
    if (loggedInUser != null) {
      isLoggedIn.value = true;
      currentUser.value = loggedInUser;
    }
  }

  Box<User> getUserBox() => _userBox;

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> signup(
      String email,
      String username,
      String password, {
        String? role,
        List<String>? allowedOptions,
      }) async {
    isLoading.value = true;
    try {
      if (_userBox.values.any((user) => user.username == username || user.email == email)) {
        Get.snackbar('Error', 'Username or email already exists',
            backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
        return false;
      }
      final effectiveRole = role ?? 'user';
      final effectiveOptions = effectiveRole == 'staff'
          ? allowedOptions
          : effectiveRole == 'admin'
          ? ['Dashboard', 'Services', 'Generate Invoice', 'Finance', 'Expenses']
          : null;
      final user = User(
        username: username,
        email: email,
        hashedPassword: hashPassword(password),
        isLoggedIn: true,
        role: effectiveRole,
        allowedOptions: effectiveOptions,
      );
      await _userBox.add(user);
      isLoggedIn.value = true;
      currentUser.value = user;
      await Get.find<DataController>().loadData();
      await Get.find<AppointmentController>().loadAppointments();
      isLoading.value = false;
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign up');
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    try {
      final hashedPassword = hashPassword(password);
      final user = _userBox.values.firstWhereOrNull(
            (user) => user.email == email && user.hashedPassword == hashedPassword,
      );
      if (user != null) {
        isLoggedIn.value = true;
        currentUser.value = user;
        final index = _userBox.values.toList().indexWhere((u) => u.email == email);
        await _userBox.putAt(
          index,
          User(
            username: user.username,
            email: user.email,
            hashedPassword: user.hashedPassword,
            role: user.role,
            isLoggedIn: true,
            profilePicturePath: user.profilePicturePath,
            allowedOptions: user.allowedOptions,
          ),
        );
        await Get.find<DataController>().loadData();
        await Get.find<AppointmentController>().loadAppointments();
        isLoading.value = false;
        return true;
      } else {
        Get.snackbar('Error', 'Invalid email or password',
            backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to login');
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> resetPassword(String email, String newPassword) async {
    isLoading.value = true;
    try {
      final index = _userBox.values.toList().indexWhere((user) => user.email == email);
      if (index != -1) {
        final user = _userBox.getAt(index)!;
        await _userBox.putAt(
          index,
          User(
            username: user.username,
            email: user.email,
            hashedPassword: hashPassword(newPassword),
            role: user.role,
            isLoggedIn: user.isLoggedIn,
            profilePicturePath: user.profilePicturePath,
            allowedOptions: user.allowedOptions,
          ),
        );
        isLoading.value = false;
        return true;
      } else {
        Get.snackbar('Error', 'Email not found',
            backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to reset password');
      isLoading.value = false;
      return false;
    }
  }

  void logout() {
    final user = currentUser.value;
    if (user != null) {
      final index = _userBox.values.toList().indexWhere((u) => u.email == user.email);
      if (index != -1) {
        _userBox.putAt(
          index,
          User(
            username: user.username,
            email: user.email,
            hashedPassword: user.hashedPassword,
            role: user.role,
            isLoggedIn: false,
            profilePicturePath: user.profilePicturePath,
            allowedOptions: user.allowedOptions,
          ),
        );
      }
    }
    isLoggedIn.value = false;
    currentUser.value = null;
    Get.offAllNamed('/login');
  }

  bool isRouteAllowed(String route) {
    if (currentUser.value?.role != 'staff') return true;

    // Default routes always allowed for staff
    const defaultRoutes = [
      '/dashboard',
      '/services',
      '/generate-invoice',
      '/staff-navbar',
    ];
    if (defaultRoutes.contains(route)) return true;

    // Map permissions to routes
    final allowedRoutes = currentUser.value?.allowedOptions?.map((label) {
      return {
        'Dashboard': '/dashboard',
        'Services': '/services',
        'Generate Invoice': '/generate-invoice',
        'Finance': '/finance',
        'Expenses': '/expenses',
      }[label];
    }).toList();

    return allowedRoutes?.contains(route) ?? false;
  }
}