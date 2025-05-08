import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Controllers/authController.dart';
import 'screen/settingScreen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final GetStorage storage = GetStorage();
    final AuthController authController = Get.find<AuthController>();
    final String shopName = storage.read('shopName') ?? 'My Barber Shop';
    final isAdmin = authController.currentUser.value?.role != 'staff';

    void showEditShopNameDialog() {
      final TextEditingController shopNameController = TextEditingController(
        text: shopName,
      );
      Get.dialog(
        AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Edit Shop Name',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: TextField(
            controller: shopNameController,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: 'Enter shop name',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = shopNameController.text.trim();
                if (newName.isNotEmpty) {
                  storage.write('shopName', newName);
                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Shop name updated',
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    colorText: Theme.of(context).colorScheme.onPrimary,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Shop name cannot be empty',
                    backgroundColor: Colors.red,
                    colorText: Theme.of(context).colorScheme.onTertiary,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 150,
            color: Theme.of(context).colorScheme.secondary,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Obx(() => CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    backgroundImage: authController.currentUser.value?.profilePicturePath != null &&
                        authController.currentUser.value!.profilePicturePath!.isNotEmpty
                        ? GetPlatform.isWeb
                        ? MemoryImage(base64Decode(authController.currentUser.value!.profilePicturePath!))
                        : FileImage(File(authController.currentUser.value!.profilePicturePath!))
                        : null,
                    child: authController.currentUser.value?.profilePicturePath == null ||
                        authController.currentUser.value!.profilePicturePath!.isEmpty
                        ? Icon(
                      Icons.person,
                      size: 40,
                      color: Theme.of(context).colorScheme.onTertiary,
                    )
                        : null,
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          style: GoogleFonts.dancingScript(
                            textStyle: Theme.of(context).textTheme.displayLarge,
                            fontSize: 30,
                            fontWeight: FontWeight.w200,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: showEditShopNameDialog,
                  ),
                ],
              ),
            ),
          ),
          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(
                    'Profile',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Get.back(); // Close drawer
                    Get.toNamed('/profile');
                  },
                ),
                if (isAdmin) // Show Assign Auth only for admins
                  ListTile(
                    leading: Icon(
                      Icons.add_circle,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    title: Text(
                      'Assign Auth',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Get.back(); // Close drawer
                      Get.toNamed('/staff-management');
                    },
                  ),
                ListTile(
                  leading: Icon(
                    Icons.settings,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(
                    'Settings',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Get.back(); // Close drawer
                    Get.to(const SettingsPage());
                  },
                ),
              ],
            ),
          ),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Get.defaultDialog(
                  title: 'Logout',
                  middleText: 'Are you sure you want to logout?',
                  textConfirm: 'Yes',
                  textCancel: 'No',
                  confirmTextColor: Theme.of(context).colorScheme.onPrimary,
                  onConfirm: () {
                    authController.logout();
                  },
                );
              },
              icon: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              label: Text(
                'Logout',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}