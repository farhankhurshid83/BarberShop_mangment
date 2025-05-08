import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/adapters.dart';
import '../../Controllers/authController.dart';
import '../../Controllers/themeController.dart';
import '../../Classes/user.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  _StaffManagementScreenState createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final AuthController authController = Get.find<AuthController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxList<String> selectedPermissions = <String>[].obs;
  final RxBool obscurePassword = true.obs;
  late final RxList<User> staffList;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Define all possible permissions based on provided routes
  static const List<String> allPermissions = [
    'Services',
    'Generate Invoice',
    'Finance',
    'Expenses',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize staffList
    staffList = RxList<User>(
      authController
          .getUserBox()
          .values
          .where((user) => user.role == 'staff')
          .toList(),
    );

    // Add listener to Hive box
    authController.getUserBox().listenable().addListener(_updateStaffList);

    // Debug: Log currentUser.allowedOptions
    debugPrint('Current user: ${authController.currentUser.value?.email}, role: ${authController.currentUser.value?.role}');
    debugPrint('Current user allowedOptions: ${authController.currentUser.value?.allowedOptions}');
  }

  void _updateStaffList() {
    staffList.assignAll(
      authController.getUserBox().values.where((user) => user.role == 'staff').toList(),
    );
  }

  @override
  void dispose() {
    // Clean up listener
    authController.getUserBox().listenable().removeListener(_updateStaffList);
    // Dispose controllers
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void addStaff() async {
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Username, email, and password are required',
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
      );
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(emailController.text.trim())) {
      Get.snackbar(
        'Error',
        'Invalid email format',
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
      );
      return;
    }
    if (passwordController.text.length < 8) {
      Get.snackbar(
        'Error',
        'Password must be at least 8 characters long',
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
      );
      return;
    }
    if (selectedPermissions.isEmpty) {
      Get.snackbar(
        'Error',
        'At least one permission must be selected',
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
      );
      return;
    }
    final success = await authController.signup(
      emailController.text.trim(),
      usernameController.text.trim(),
      passwordController.text.trim(),
      role: 'staff',
      allowedOptions: selectedPermissions.toList(),
    );
    if (success) {
      Get.snackbar(
        'Success',
        'Staff member added successfully',
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
        colorText: Theme.of(context).colorScheme.onPrimary,
      );
      usernameController.clear();
      emailController.clear();
      passwordController.clear();
      selectedPermissions.clear();
    }
  }

  void editStaff(User staff) {
    final editUsernameController = TextEditingController(text: staff.username);
    final editEmailController = TextEditingController(text: staff.email);
    final editPasswordController = TextEditingController();
    final RxList<String> editPermissions = (staff.allowedOptions ?? []).obs;
    final RxBool editObscurePassword = true.obs;

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Edit Staff',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: editUsernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person),
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
              ),
              const SizedBox(height: 16),
              TextField(
                controller: editEmailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
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
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              Obx(() => TextField(
                controller: editPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password (Optional)',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      editObscurePassword.value ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () => editObscurePassword.toggle(),
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
                obscureText: editObscurePassword.value,
              )),
              const SizedBox(height: 16),
              Text(
                'Permissions (Required)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(() {
                final isAdmin = authController.currentUser.value?.role != 'staff';
                final permissions = isAdmin
                    ? allPermissions
                    : (authController.currentUser.value?.allowedOptions ?? []);
                return Column(
                  children: permissions.isEmpty
                      ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No permissions available',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ]
                      : permissions
                      .map((permission) => CheckboxListTile(
                    title: Text(
                      permission,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    value: editPermissions.contains(permission),
                    onChanged: (value) {
                      if (value == true) {
                        editPermissions.add(permission);
                      } else {
                        editPermissions.remove(permission);
                      }
                    },
                    activeColor: Theme.of(context).colorScheme.secondary,
                    checkColor: Theme.of(context).colorScheme.onTertiary,
                  ))
                      .toList(),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editUsernameController.text.isEmpty || editEmailController.text.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Username and email are required',
                  backgroundColor: Theme.of(context).colorScheme.error,
                  colorText: Theme.of(context).colorScheme.onError,
                );
                return;
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(editEmailController.text.trim())) {
                Get.snackbar(
                  'Error',
                  'Invalid email format',
                  backgroundColor: Theme.of(context).colorScheme.error,
                  colorText: Theme.of(context).colorScheme.onError,
                );
                return;
              }
              if (editPasswordController.text.isNotEmpty &&
                  editPasswordController.text.length < 8) {
                Get.snackbar(
                  'Error',
                  'New password must be at least 8 characters long',
                  backgroundColor: Theme.of(context).colorScheme.error,
                  colorText: Theme.of(context).colorScheme.onError,
                );
                return;
              }
              if (editPermissions.isEmpty) {
                Get.snackbar(
                  'Error',
                  'At least one permission must be selected',
                  backgroundColor: Theme.of(context).colorScheme.error,
                  colorText: Theme.of(context).colorScheme.onError,
                );
                return;
              }
              try {
                final userIndex = authController
                    .getUserBox()
                    .values
                    .toList()
                    .indexWhere((u) => u.email == staff.email);
                if (userIndex == -1) {
                  Get.snackbar(
                    'Error',
                    'Staff member not found',
                    backgroundColor: Theme.of(context).colorScheme.error,
                    colorText: Theme.of(context).colorScheme.onError,
                  );
                  return;
                }
                final updatedUser = User(
                  username: editUsernameController.text.trim(),
                  email: editEmailController.text.trim(),
                  hashedPassword: editPasswordController.text.isEmpty
                      ? staff.hashedPassword
                      : authController.hashPassword(editPasswordController.text.trim()),
                  role: staff.role,
                  allowedOptions: editPermissions.toList(),
                  isLoggedIn: staff.isLoggedIn,
                  profilePicturePath: staff.profilePicturePath,
                );
                await authController.getUserBox().putAt(userIndex, updatedUser);
                Get.back();
                Get.snackbar(
                  'Success',
                  'Staff member updated successfully',
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  colorText: Theme.of(context).colorScheme.onPrimary,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to update staff: $e',
                  backgroundColor: Theme.of(context).colorScheme.error,
                  colorText: Theme.of(context).colorScheme.onError,
                );
              }
              // Dispose dialog controllers
              editUsernameController.dispose();
              editEmailController.dispose();
              editPasswordController.dispose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onTertiary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent default back button
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            debugPrint('Drawer button pressed, scaffoldKey.currentState: ${scaffoldKey.currentState}');
            if (scaffoldKey.currentState != null && scaffoldKey.currentState!.isDrawerOpen) {
              scaffoldKey.currentState!.closeDrawer();
            } else if (scaffoldKey.currentState != null) {
              scaffoldKey.currentState!.openDrawer();
              debugPrint('Opening drawer');
            } else {
              debugPrint('ScaffoldState is null, cannot open drawer');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add Staff Form
              Card(
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Staff',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(Icons.person),
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
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
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
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      Obx(() => TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            onPressed: () => obscurePassword.toggle(),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
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
                          fillColor:
                          Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        obscureText: obscurePassword.value,
                      )),
                      const SizedBox(height: 16),
                      Text(
                        'Permissions (Required)',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Obx(() => Column(
                        children: allPermissions.isEmpty
                            ? [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No permissions available',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ]
                            : allPermissions
                            .map((permission) => CheckboxListTile(
                          title: Text(
                            permission,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          value: selectedPermissions.contains(permission),
                          onChanged: (value) {
                            if (value == true) {
                              selectedPermissions.add(permission);
                            } else {
                              selectedPermissions.remove(permission);
                            }
                          },
                          activeColor: Theme.of(context).colorScheme.secondary,
                          checkColor: Theme.of(context).colorScheme.onTertiary,
                        ))
                            .toList(),
                      )),
                      const SizedBox(height: 16),
                      Center(
                        child: Obx(() {
                          return authController.isLoading.value
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                            onPressed: addStaff,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(context).colorScheme.onTertiary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Add Staff'),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Staff List
              Text(
                'Staff Members',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => staffList.isEmpty
                  ? Center(
                child: Text(
                  'No staff members found',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
              )
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: staffList.length,
                itemBuilder: (context, index) {
                  final staff = staffList[index];
                  return Card(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(
                        staff.email,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onTertiary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Username: ${staff.username}\nPassword: ••••••••',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onTertiary
                              .withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Theme.of(context).colorScheme.onTertiary,
                            ),
                            tooltip: 'Edit Staff',
                            onPressed: () => editStaff(staff),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Staff',
                            onPressed: () async {
                              final confirm = await Get.dialog<bool>(
                                AlertDialog(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  title: const Text('Delete Staff'),
                                  content: Text(
                                      'Are you sure you want to delete ${staff.email}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(result: false),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Get.back(result: true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  final userIndex = authController
                                      .getUserBox()
                                      .values
                                      .toList()
                                      .indexWhere((u) => u.email == staff.email);
                                  if (userIndex != -1) {
                                    await authController.getUserBox().deleteAt(userIndex);
                                    Get.snackbar(
                                      'Success',
                                      'Staff member deleted',
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.8),
                                      colorText: Theme.of(context).colorScheme.onPrimary,
                                    );
                                  } else {
                                    Get.snackbar(
                                      'Error',
                                      'Staff member not found',
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                      colorText: Theme.of(context).colorScheme.onError,
                                    );
                                  }
                                } catch (e) {
                                  Get.snackbar(
                                    'Error',
                                    'Failed to delete staff: $e',
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                    colorText: Theme.of(context).colorScheme.onError,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              )),
            ],
          ),
        ),
      ),
    );
  }
}