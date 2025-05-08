import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../Classes/staff.dart';
import '../../../Controllers/dataController.dart';
import '../../../Controllers/themeController.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  _StaffPageState createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final DataController dataController = Get.find<DataController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final ImagePicker _picker = ImagePicker();

  // Show staff details in a dialog
  void _showStaffDialog(Staff staff) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Staff Details',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: staff.profilePicturePath != null
                        ? FileImage(File(staff.profilePicturePath!))
                        : null,
                    child: staff.profilePicturePath == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Name: ${staff.name}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Salary: ${themeController.currencySymbol.value}${staff.salary.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact: ${staff.contact}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Address: ${staff.address}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Role: ${staff.role}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const Divider(),
                Center(
                  child: Text(
                    '#${staff.name}#',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                ElevatedButton(
                  onPressed: () => _showEditStaffDialog(staff),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 3),
                ElevatedButton(
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'Delete Staff',
                      middleText: 'Are you sure you want to delete ${staff.name}?',
                      textConfirm: 'Yes',
                      textCancel: 'No',
                      confirmTextColor: Theme.of(context).colorScheme.onPrimary,
                      onConfirm: () {
                        dataController.removeStaff(staff.name);
                        Get.back(); // Close confirmation dialog
                        Navigator.pop(context); // Close details dialog
                        Get.snackbar(
                          'Success',
                          'Staff deleted successfully',
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                          colorText: Theme.of(context).colorScheme.onPrimary,
                        );
                      },
                      onCancel: () {},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Show add/edit staff dialog
  void _showAddEditStaffDialog({Staff? staff}) {
    final isEdit = staff != null;
    final nameController = TextEditingController(text: isEdit ? staff.name : '');
    final salaryController = TextEditingController(text: isEdit ? staff.salary.toString() : '');
    final contactController = TextEditingController(text: isEdit ? staff.contact : '');
    final addressController = TextEditingController(text: isEdit ? staff.address : '');
    String? selectedRole = isEdit ? staff.role : null;
    String? profilePicturePath = isEdit ? staff.profilePicturePath : null;

    final List<String> roles = [
      'Barber',
      'Assistant',
      'Manager',
      'Receptionist',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickImage(ImageSource source) async {
              final XFile? image = await _picker.pickImage(source: source);
              if (image != null) {
                setState(() {
                  profilePicturePath = image.path;
                });
              }
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                isEdit ? 'Edit Staff' : 'Add Staff',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera),
                                  title: const Text('Camera'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.camera);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Gallery'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.gallery);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: profilePicturePath != null
                              ? FileImage(File(profilePicturePath!))
                              : null,
                          child: profilePicturePath == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: salaryController,
                      decoration: InputDecoration(
                        labelText: 'Salary',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: contactController,
                      decoration: InputDecoration(
                        labelText: 'Contact',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 15,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLength: 100,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Role',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      ),
                      value: selectedRole,
                      hint: Text(
                        'Select Role',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      items: roles
                          .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(
                          role,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value;
                        });
                      },
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      isExpanded: true,
                    ),
                  ],
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
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final salaryText = salaryController.text.trim();
                    final contact = contactController.text.trim();
                    final address = addressController.text.trim();

                    if (name.isEmpty ||
                        salaryText.isEmpty ||
                        contact.isEmpty ||
                        address.isEmpty ||
                        selectedRole == null) {
                      Get.snackbar(
                        'Error',
                        'Please fill in all required fields',
                        backgroundColor: Theme.of(context).colorScheme.error,
                        colorText: Theme.of(context).colorScheme.onError,
                      );
                      return;
                    }

                    final salary = double.tryParse(salaryText);
                    if (salary == null) {
                      Get.snackbar(
                        'Error',
                        'Please enter a valid salary',
                        backgroundColor: Theme.of(context).colorScheme.error,
                        colorText: Theme.of(context).colorScheme.onError,
                      );
                      return;
                    }

                    if (isEdit) {
                      final updatedStaff = Staff(
                        name: name,
                        salary: salary,
                        contact: contact,
                        address: address,
                        role: selectedRole!,
                        profilePicturePath: profilePicturePath,
                      );
                      dataController.updateStaff(updatedStaff);
                      Get.snackbar(
                        'Success',
                        'Staff updated successfully',
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                        colorText: Theme.of(context).colorScheme.onPrimary,
                      );
                    } else {
                      if (dataController.staff.any((s) => s.name == name)) {
                        Get.snackbar(
                          'Error',
                          'Staff with this name already exists',
                          backgroundColor: Theme.of(context).colorScheme.error,
                          colorText: Theme.of(context).colorScheme.onError,
                        );
                        return;
                      }

                      final newStaff = Staff(
                        name: name,
                        salary: salary,
                        contact: contact,
                        address: address,
                        role: selectedRole!,
                        profilePicturePath: profilePicturePath,
                      );
                      dataController.addStaff(newStaff);
                      Get.snackbar(
                        'Success',
                        'Staff added successfully',
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                        colorText: Theme.of(context).colorScheme.onPrimary,
                      );
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isEdit ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Wrapper for edit dialog to close details dialog before opening edit dialog
  void _showEditStaffDialog(Staff staff) {
    Navigator.pop(context); // Close the details dialog
    _showAddEditStaffDialog(staff: staff);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Team',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(() {
            final staffList = dataController.staff;
            return staffList.isEmpty
                ? Center(
              child: Text(
                'No staff available.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
                : ListView.builder(
              itemCount: staffList.length,
              itemBuilder: (context, index) {
                final staff = staffList[index];
                return Card(
                  color: Theme.of(context).colorScheme.secondary,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundImage: staff.profilePicturePath != null
                          ? FileImage(File(staff.profilePicturePath!))
                          : null,
                      child: staff.profilePicturePath == null
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    title: Text(
                      staff.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Ph: ${staff.contact}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiary,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '${themeController.currencySymbol.value}${staff.salary.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _showStaffDialog(staff),
                  ),
                );
              },
            );
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditStaffDialog(),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add),
      ),
    );
  }
}