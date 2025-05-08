import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import '../../../Controllers/themeController.dart';

class CustomizeAppPage extends StatelessWidget {
  const CustomizeAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final TextEditingController codeController = TextEditingController();
    final TextEditingController symbolController = TextEditingController();

    // List of available secondary and text colors
    final List<Color> colorOptions = [
      const Color(0xffff9900), // Orange
      Colors.red,
      Colors.green,
      Color(0xff0027ff),
      Colors.purple,
      Colors.teal,
      Colors.cyan
    ];

    final List<Color> textColorOptions = [
      Colors.white, // Default
      Colors.black,
      Colors.grey,
      Colors.yellow,
      Colors.cyan,
      Colors.pink,
    ];

    // Show dialog to add custom currency
    void showAddCurrencyDialog() {
      Get.dialog(
        AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Add Custom Currency',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Currency Code (e.g., AUD)',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w300,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: symbolController,
                decoration: InputDecoration(
                  labelText: 'Currency Symbol (e.g., A\$)',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                codeController.clear();
                symbolController.clear();
                Get.back();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final code = codeController.text.trim().toUpperCase();
                final symbol = symbolController.text.trim();

                if (code.isEmpty || symbol.isEmpty) {
                  Get.closeAllSnackbars();
                  Get.snackbar(
                    'Error',
                    'Please enter both currency code and symbol',
                    backgroundColor: Theme.of(context).colorScheme.error,
                    colorText: Theme.of(context).colorScheme.onError,
                  );
                  return;
                }

                if (themeController.currencyOptions.any((c) => c['code'] == code)) {
                  Get.closeAllSnackbars();
                  Get.snackbar(
                    'Error',
                    'Currency code already exists',
                    backgroundColor: Theme.of(context).colorScheme.error,
                    colorText: Theme.of(context).colorScheme.onError,
                  );
                  return;
                }

                themeController.addCurrency(code, symbol);
                Get.closeAllSnackbars();
                Get.snackbar(
                  'Success',
                  'Currency $code added',
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  colorText: Theme.of(context).colorScheme.onPrimary,
                );

                codeController.clear();
                symbolController.clear();
                Get.back();
              },
              child: Text(
                'Add',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Helper function for contrast color
    Color getContrastColor(Color color) {
      double luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
      return luminance > 0.5 ? Colors.black : Colors.white;
    }

    // Show color picker dialog for secondary color
    void showSecondaryColorPickerDialog() {
      Color selectedColor = themeController.secondaryColor.value;
      final List<Color> disabledColors = [
        Colors.red,
        Colors.blue,
      ];
      Get.dialog(
        AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Pick a Secondary Color',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                selectedColor = color;
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                try {
                  if (disabledColors.contains(selectedColor)) {
                    Get.closeAllSnackbars();
                    Get.snackbar(
                      'Error',
                      'This color is not allowed',
                      backgroundColor: Theme.of(context).colorScheme.error,
                      colorText: Theme.of(context).colorScheme.onError,
                      duration: const Duration(seconds: 3),
                    );
                    return;
                  }
                  themeController.changeSecondaryColor(selectedColor);
                  Get.closeAllSnackbars();
                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Secondary color changed successfully',
                    backgroundColor: selectedColor,
                    colorText: getContrastColor(selectedColor),
                    duration: const Duration(seconds: 3),
                  );
                } catch (e) {
                  Get.closeAllSnackbars();
                  Get.back();
                  Get.snackbar(
                    'Error',
                    'Failed to update color',
                    backgroundColor: Theme.of(context).colorScheme.error,
                    colorText: Theme.of(context).colorScheme.onError,
                    duration: const Duration(seconds: 3),
                  );
                }
              },
              child: Text(
                'Select',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show color picker dialog for text color
    void showTextColorPickerDialog() {
      Color selectedColor = themeController.onTertiaryColor.value;
      Get.dialog(
        AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Pick a Text Color',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                selectedColor = color;
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                try {
                  themeController.changeTextColor(selectedColor);
                  Get.closeAllSnackbars();
                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Text color changed successfully',
                    backgroundColor: selectedColor,
                    colorText: getContrastColor(selectedColor),
                    duration: const Duration(seconds: 3),
                  );
                } catch (e) {
                  Get.closeAllSnackbars();
                  Get.back();
                  Get.snackbar(
                    'Error',
                    'Failed to update text color',
                    backgroundColor: Theme.of(context).colorScheme.error,
                    colorText: Theme.of(context).colorScheme.onError,
                    duration: const Duration(seconds: 3),
                  );
                }
              },
              child: Text(
                'Select',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Customize App',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Change App Color Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change App Color',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  height: 60,
                  width: MediaQuery.of(context).size.width,
                  child: Center(
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 10,
                      children: colorOptions.map((color) {
                        return GestureDetector(
                          onTap: () {
                            themeController.changeSecondaryColor(color);
                            Get.closeAllSnackbars();
                            Get.snackbar(
                              'Success',
                              'Secondary color updated',
                              backgroundColor: color,
                              colorText: themeController.onTertiaryColor.value,
                            );
                          },
                          child: Obx(() => Container(
                            width: 40, // Fixed size for consistency
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white, // White border
                                width: 2, // Border width
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 20, // Matches container size
                              backgroundColor: color,
                              child: themeController.secondaryColor.value == color
                                  ? Icon(
                                Icons.check,
                                color: themeController.onTertiaryColor.value,
                                size: 20,
                              )
                                  : null,
                            ),
                          )),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: showSecondaryColorPickerDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pick a Custom Color',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          Icons.color_lens,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Change Text Color Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Text Color',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  height: 60,
                  width: MediaQuery.of(context).size.width,
                  child: Center(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: textColorOptions.map((color) {
                        return GestureDetector(
                          onTap: () {
                            themeController.changeTextColor(color);
                            Get.closeAllSnackbars();
                            Get.snackbar(
                              'Success',
                              'Text color updated',
                              backgroundColor: color,
                              colorText: getContrastColor(color),
                            );
                          },
                          child: Obx(() => Container(
                            width: 40, // Fixed size for consistency
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white, // White border
                                width: 2, // Border width
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 20, // Matches container size
                              backgroundColor: color,
                              child: themeController.onTertiaryColor.value == color
                                  ? Icon(
                                Icons.check,
                                color: getContrastColor(color),
                                size: 20,
                              )
                                  : null,
                            ),
                          )),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: showTextColorPickerDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pick a Custom Text Color',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          Icons.color_lens,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Change Currency Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Change Currency',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: showAddCurrencyDialog,
                    ),
                  ],
                ),
                Obx(() {
                  return DropdownButton<String>(
                    isExpanded: true,
                    value: themeController.currency.value,
                    items: themeController.currencyOptions.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency['code'],
                        child: Text(
                          '${currency['code']} (${currency['symbol']})',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final selectedCurrency = themeController.currencyOptions
                            .firstWhere((c) => c['code'] == value);
                        themeController.changeCurrency(value, selectedCurrency['symbol']!);
                        Get.closeAllSnackbars();
                        Get.snackbar(
                          'Success',
                          'Currency updated to $value',
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          colorText: themeController.onTertiaryColor.value,
                        );
                      }
                    },
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}