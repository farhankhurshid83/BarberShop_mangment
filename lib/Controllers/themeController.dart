import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final GetStorage storage = GetStorage();
  var isDarkMode = true.obs;
  var secondaryColor = const Color(0xffff9900).obs; // Default secondary color
  var onTertiaryColor = Colors.white.obs; // Default text color (onTertiary)
  var currency = 'USD'.obs;
  var currencySymbol = '\$'.obs;
  var currencyOptions = <Map<String, String>>[
    {'code': 'USD', 'symbol': '\$'},
    {'code': 'PKR', 'symbol': 'Rs'},
    {'code': 'EUR', 'symbol': '€'},
    {'code': 'GBP', 'symbol': '£'},
    {'code': 'INR', 'symbol': '₹'},
    {'code': 'JPY', 'symbol': '¥'},
  ].obs;

  @override
  void onInit() {
    // Load saved settings
    isDarkMode.value = storage.read('isDarkMode') ?? true;
    final storedColor = storage.read('secondaryColor');
    if (storedColor != null) {
      secondaryColor.value = Color(storedColor);
    }
    final storedTextColor = storage.read('onTertiaryColor');
    if (storedTextColor != null) {
      onTertiaryColor.value = Color(storedTextColor);
    }
    if (storage.read('currency') != null) {
      currency.value = storage.read('currency');
      currencySymbol.value = storage.read('currencySymbol') ?? '\$';
    }
    if (storage.read('currencyOptions') != null) {
      currencyOptions.assignAll(
        List<Map<String, String>>.from(
          storage.read('currencyOptions').map((item) => Map<String, String>.from(item)),
        ),
      );
    }
    updateTheme();
    super.onInit();
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    storage.write('isDarkMode', isDarkMode.value);
    updateTheme();
  }

  void changeSecondaryColor(Color color) {
    secondaryColor.value = color;
    storage.write('secondaryColor', color.value);
    updateTheme();
  }

  void changeTextColor(Color color) {
    onTertiaryColor.value = color;
    storage.write('onTertiaryColor', color.value);
    updateTheme();
  }

  void changeCurrency(String code, String symbol) {
    currency.value = code;
    currencySymbol.value = symbol;
    storage.write('currency', code);
    storage.write('currencySymbol', symbol);
  }

  void addCurrency(String code, String symbol) {
    currencyOptions.add({'code': code, 'symbol': symbol});
    storage.write('currencyOptions', currencyOptions.map((c) => Map<String, String>.from(c)).toList());
  }

  void updateTheme() {
    Get.changeTheme(isDarkMode.value ? darkTheme() : lightTheme());
  }

  ThemeData darkTheme() {
    return ThemeData(
      scaffoldBackgroundColor: Colors.black,
      primaryColor: Colors.blue,
      colorScheme: ColorScheme.dark(
        primary: Colors.blue,
        secondary: secondaryColor.value,
        surface: Colors.grey.shade900,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onTertiary: onTertiaryColor.value, // Use dynamic text color
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: onTertiaryColor.value),
        bodyMedium: TextStyle(color: onTertiaryColor.value),
        labelLarge: TextStyle(color: onTertiaryColor.value),
      ),
      iconTheme: IconThemeData(color: onTertiaryColor.value),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor.value,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade800,
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  ThemeData lightTheme() {
    return ThemeData(
      scaffoldBackgroundColor: Colors.white,
      primaryColor: Colors.blue,
      colorScheme: ColorScheme.light(
        primary: Colors.blue,
        secondary: secondaryColor.value,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black87,
        onTertiary: onTertiaryColor.value, // Use dynamic text color
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: onTertiaryColor.value),
        bodyMedium: TextStyle(color: onTertiaryColor.value),
        labelLarge: TextStyle(color: onTertiaryColor.value),
      ),
      iconTheme: IconThemeData(color: onTertiaryColor.value),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor.value,
          foregroundColor: Colors.black,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade200,
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}