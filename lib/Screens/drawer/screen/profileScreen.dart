import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../Classes/user.dart';
import '../../../Controllers/authController.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final TextEditingController nameController = TextEditingController(
      text: authController.currentUser.value?.username ?? 'Barber',
    );
    final RxString profilePicturePath = (authController.currentUser.value?.profilePicturePath ?? '').obs;

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (GetPlatform.isWeb) {
          final bytes = await pickedFile.readAsBytes();
          profilePicturePath.value = base64Encode(bytes);
        } else {
          final dir = await getApplicationDocumentsDirectory();
          final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final path = '${dir.path}/$fileName';
          await File(pickedFile.path).copy(path);
          profilePicturePath.value = path;
        }
      }
    }

    void saveChanges() async {
      final user = authController.currentUser.value;
      if (user == null) {
        Get.snackbar('Error', 'No user logged in');
        return;
      }
      final index = authController.getUserBox().values.toList().indexWhere((u) => u.email == user.email);
      if (index != -1 && nameController.text.isNotEmpty) {
        final updatedUser = User(
          username: nameController.text.trim(),
          email: user.email,
          hashedPassword: user.hashedPassword,
          role: user.role,
          isLoggedIn: user.isLoggedIn,
          profilePicturePath: profilePicturePath.value.isNotEmpty ? profilePicturePath.value : user.profilePicturePath,
        );
        await authController.getUserBox().putAt(index, updatedUser);
        authController.currentUser.value = updatedUser;
      Get.snackbar(
          'Success',
          'Profile updated',
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          colorText: Theme.of(context).colorScheme.onPrimary,
        );
      } else {
        Get.snackbar('Error', 'Name cannot be empty');
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Profile',
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              Obx(() => Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    backgroundImage: profilePicturePath.value.isNotEmpty
                        ? GetPlatform.isWeb
                        ? MemoryImage(base64Decode(profilePicturePath.value))
                        : FileImage(File(profilePicturePath.value))
                        : null,
                    child: profilePicturePath.value.isEmpty
                        ? Icon(
                      Icons.person,
                      size: 60,
                      color: Theme.of(context).colorScheme.onTertiary,
                    )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          Icons.edit,
                          size: 15,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onTertiary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onTertiary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}