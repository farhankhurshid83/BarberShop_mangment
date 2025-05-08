import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' show ImageFilter;
import '../Classes/serviceClass.dart';
import '../Controllers/dataController.dart';
import '../Controllers/themeController.dart';
import 'Classes/category.dart';

class CategoryServicesScreen extends StatefulWidget {
  final String category;
  final List<Service> services;

  const CategoryServicesScreen({
    super.key,
    required this.category,
    required this.services,
  });

  @override
  _CategoryServicesScreenState createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  final DataController dataController = Get.find<DataController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageController = TextEditingController();
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
        _imageController.text = image.path;
      });
    }
  }

  void _addService() {
    final name = _nameController.text;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final category = widget.category;
    final imagePath = _imageController.text.isNotEmpty
        ? _imageController.text
        : 'assets/images/customer.png';

    if (name.isNotEmpty && price > 0) {
      final newService = Service(
        name: name,
        price: price,
        category: category,
        icon: _getIconForCategory(category),
        imagePath: imagePath,
        isAsset: _pickedImage == null,
      );
      dataController.addService(newService);
      _nameController.clear();
      _priceController.clear();
      _imageController.clear();
      setState(() => _pickedImage = null);
      Navigator.pop(context);
    } else {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
      );
    }
  }

  void _updateService(int index, Service originalService) {
    final name = _nameController.text;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final imagePath = _imageController.text.isNotEmpty
        ? _imageController.text
        : originalService.imagePath;

    if (name.isNotEmpty && price > 0) {
      final updatedService = Service(
        name: name,
        price: price,
        category: widget.category,
        icon: _getIconForCategory(widget.category),
        imagePath: imagePath,
        isAsset: _pickedImage == null ? originalService.isAsset : false,
      );
      dataController.updateService(index, updatedService);
      _nameController.clear();
      _priceController.clear();
      _imageController.clear();
      setState(() => _pickedImage = null);
      Navigator.pop(context);
    } else {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
      );
    }
  }

  Future<void> _showAddServiceDialog(BuildContext context) async {
    bool isLoading = false;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add Service",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, _, __) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            scrollable: true,
            title: Text(
              'Add New Service',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontFamily: 'Poppins',
              ),
            ),
            content: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Service Name',
                            hintText: 'e.g., Classic Haircut',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                            counterStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLength: 50,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Price',
                            hintText: 'e.g., 25.00',
                            prefixText: themeController.currencySymbol.value,
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            await _pickImageFromGallery();
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Pick Image',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (_pickedImage != null) ...[
                          const SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 6,
                                clipBehavior: Clip.antiAlias,
                                child: Image.file(
                                  _pickedImage!,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await _pickImageFromGallery();
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _nameController.clear();
                  _priceController.clear();
                  _imageController.clear();
                  setState(() => _pickedImage = null);
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              GestureDetector(
                onTapDown: (_) => HapticFeedback.lightImpact(),
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    setState(() => isLoading = true);
                    HapticFeedback.lightImpact();
                    _addService();
                    setState(() => isLoading = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onTertiary,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'Add',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditServiceDialog(BuildContext context, Service service, int index) async {
    bool isLoading = false;

    // Pre-fill fields with current service data
    _nameController.text = service.name;
    _priceController.text = service.price.toStringAsFixed(2);
    _imageController.text = service.imagePath;
    _pickedImage = service.isAsset ? null : File(service.imagePath);

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Edit Service",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, _, __) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            scrollable: true,
            title: Text(
              'Edit Service',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontFamily: 'Poppins',
              ),
            ),
            content: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Service Name',
                            hintText: 'e.g., Classic Haircut',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                            counterStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLength: 50,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Price',
                            hintText: 'e.g., 25.00',
                            prefixText: themeController.currencySymbol.value,
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            await _pickImageFromGallery();
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Pick Image',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (_imageController.text.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 6,
                                clipBehavior: Clip.antiAlias,
                                child: _pickedImage != null
                                    ? Image.file(
                                  _pickedImage!,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                                    : Image(
                                  image: service.isAsset
                                      ? AssetImage(service.imagePath)
                                      : FileImage(File(service.imagePath)) as ImageProvider,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await _pickImageFromGallery();
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    _nameController.clear();
                    _priceController.clear();
                    _imageController.clear();
                    setState(() => _pickedImage = null);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    dataController.removeService(index);
                    _nameController.clear();
                    _priceController.clear();
                    _imageController.clear();
                    setState(() => _pickedImage = null);
                    Navigator.pop(context);
                    Get.snackbar(
                      'Success',
                      'Service "${service.name}" deleted',
                      backgroundColor: Colors.red,
                      colorText:  Theme.of(context).colorScheme.onTertiary,
                    );
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTapDown: (_) => HapticFeedback.lightImpact(),
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                      setState(() => isLoading = true);
                      HapticFeedback.lightImpact();
                      _updateService(index, service);
                      setState(() => isLoading = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onTertiary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onTertiary,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      'Update',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            )
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Service service) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          title: Text(
            'Confirm Deletion',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${service.name}"?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
            TextButton(
              onPressed: () {
                final serviceIndex = dataController.services.indexOf(service);
                if (serviceIndex != -1) {
                  dataController.removeService(serviceIndex);
                }
                Navigator.pop(context);
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getCategoryImage(String category) {
    final categoryObj = dataController.categories.firstWhere(
          (cat) => cat.name == category,
      orElse: () => Category(
        name: category,
        imagePath: 'assets/images/customer.png',
        isAsset: true,
      ),
    );
    return categoryObj.imagePath;
  }

  IconData? _getIconForCategory(String category) {
    switch (category) {
      case 'Shave':
        return Icons.account_circle_outlined;
      case 'Hair Wash':
        return Icons.bubble_chart;
      case 'Haircut':
        return Icons.content_cut;
      case 'Beard Trim':
        return Icons.face_retouching_natural;
      case 'Facial':
        return Icons.spa;
      case 'Offers':
        return Icons.local_offer;
      default:
        return Icons.miscellaneous_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DataController dataController = Get.find<DataController>();
    final categoryImage = _getCategoryImage(widget.category);

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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.category,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                height: 150,
                width: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: dataController.categories
                        .firstWhere(
                          (cat) => cat.name == widget.category,
                      orElse: () => Category(
                        name: widget.category,
                        imagePath: 'assets/images/customer.png',
                        isAsset: true,
                      ),
                    )
                        .isAsset
                        ? AssetImage(categoryImage)
                        : FileImage(File(categoryImage)) as ImageProvider,
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.1),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.category,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Obx(() {
                  final currentServices = dataController.services
                      .where((service) => service.category == widget.category)
                      .toList();
                  if (currentServices.isEmpty) {
                    return Center(
                      child: Text(
                        'No services available in this category.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: currentServices.length,
                    itemBuilder: (context, index) {
                      final service = currentServices[index];
                      return Card(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image: service.isAsset
                                            ? AssetImage(service.imagePath) as ImageProvider
                                            : FileImage(File(service.imagePath)),
                                        fit: BoxFit.cover,
                                        colorFilter: ColorFilter.mode(
                                          Colors.black.withValues(alpha: 0.2),
                                          BlendMode.darken,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    service.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(context).colorScheme.onTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${themeController.currencySymbol.value}${service.price.toStringAsFixed(2)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(context).colorScheme.onTertiary,
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () async {
                                    final serviceIndex = dataController.services.indexOf(service);
                                    if (serviceIndex != -1) {
                                      _showEditServiceDialog(context, service, serviceIndex);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: () => _showAddServiceDialog(context),
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onTertiary,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }
}