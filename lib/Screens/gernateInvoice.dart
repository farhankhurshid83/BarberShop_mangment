import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:memory_capsule/Classes/customer.dart';
import 'dart:ui' show ImageFilter;
import 'dart:io';
import '../Classes/invoice.dart';
import '../Controllers/dataController.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GenerateInvoiceScreen extends StatefulWidget {
  const GenerateInvoiceScreen({super.key});

  @override
  _GenerateInvoiceScreenState createState() => _GenerateInvoiceScreenState();
}

class _GenerateInvoiceScreenState extends State<GenerateInvoiceScreen> {
  final DataController dataController = Get.find<DataController>();
  final TextEditingController customerNameController = TextEditingController();
  Customer? _selectedCustomer;
  final Map<String, bool> _serviceSelection = {};
  double _total = 0.0;
  List<Customer> _suggestedCustomers = [];
  bool _isWalkIn = false;
  final GetStorage storage = GetStorage();
  final FocusNode _customerNameFocus = FocusNode();

  // Get the currency symbol
  String get currencySymbol => storage.read('currencySymbol') ?? '\$';

  // Format price for invoice display (e.g., 1000 -> 1K, 1500 -> 1.5K)
  String formatPrice(double price) {
    if (price > 999) {
      final kValue = price / 1000;
      // Remove trailing zeros and decimal point if integer
      return kValue % 1 == 0 ? '${kValue.toInt()}K' : '${kValue.toStringAsFixed(1)}K';
    }
    return price.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _updateServiceSelection();
    // Add focus listener for customer name TextField
    _customerNameFocus.addListener(() {
      if (_customerNameFocus.hasFocus && customerNameController.text.trim().isEmpty) {
        setState(() {
          _suggestedCustomers = dataController.customers.toList();
        });
      }
    });
  }

  void _updateServiceSelection() {
    for (var service in dataController.services) {
      _serviceSelection.putIfAbsent(service.name, () => false);
    }
  }

  void _calculateTotal() {
    setState(() {
      _total = dataController.services
          .where((service) => _serviceSelection[service.name] == true)
          .fold(0.0, (sum, service) => sum + service.price);
    });
  }

  void _onCustomerNameChanged(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      setState(() {
        _selectedCustomer = null;
        _suggestedCustomers = dataController.customers.toList();
      });
      return;
    }

    final filteredCustomers = dataController.customers
        .where((customer) => customer.name.toLowerCase().contains(name.toLowerCase()))
        .toList();

    setState(() {
      _suggestedCustomers = filteredCustomers;
      _selectedCustomer = filteredCustomers.firstWhereOrNull(
            (customer) => customer.name.toLowerCase() == name.toLowerCase(),
      );
    });
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      customerNameController.text = customer.name;
      _suggestedCustomers = [];
    });
  }

  void _generateInvoice() {
    final name = customerNameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter a customer name');
      return;
    }

    final selectedServices = dataController.services
        .where((service) => _serviceSelection[service.name] == true)
        .map((service) => {'name': service.name, 'price': service.price})
        .toList();

    if (selectedServices.isEmpty) {
      Get.snackbar('Error', 'Please select at least one service');
      return;
    }

    if (_selectedCustomer != null) {
      _createInvoice(_selectedCustomer!);
    } else {
      _showCustomerTypeDialog(name);
    }
  }

  Future<void> _showCustomerTypeDialog(String name) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Customer Type',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Is $name a routine customer or a walk-in customer?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _isWalkIn = true;
                Navigator.pop(context);
                _createInvoice(Customer(name: name, phone: '', email: null));
              },
              child: Text(
                'Walk-in',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _isWalkIn = false;
                Navigator.pop(context);
                _showAddCustomerDetailsDialog(name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Routine',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddCustomerDetailsDialog(String initialName) async {
    final TextEditingController nameController = TextEditingController(text: initialName);
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;
    List<Customer> suggestedCustomers = [];
    final FocusNode nameFocus = FocusNode();

    // Add focus listener for name TextField
    nameFocus.addListener(() {
      if (nameFocus.hasFocus && nameController.text.trim().isEmpty) {
        setState(() {
          suggestedCustomers = dataController.customers.toList();
        });
      }
    });

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add Customer",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, _, __) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            scrollable: true,
            title: Text(
              'New Customer',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
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
                          controller: nameController,
                          focusNode: nameFocus,
                          decoration: InputDecoration(
                            labelText: 'Customer Name',
                            hintText: 'Enter customer name',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onChanged: (value) {
                            final name = value.trim();
                            if (name.isEmpty) {
                              setState(() {
                                suggestedCustomers = dataController.customers.toList();
                              });
                            } else {
                              final filteredCustomers = dataController.customers
                                  .where((customer) => customer.name.toLowerCase().contains(name.toLowerCase()))
                                  .toList();
                              setState(() {
                                suggestedCustomers = filteredCustomers;
                              });
                            }
                          },
                        ),
                        if (suggestedCustomers.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: suggestedCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = suggestedCustomers[index];
                                final emailText = customer.email ?? 'No email provided';
                                return ListTile(
                                  title: Text(
                                    customer.name,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  subtitle: Text(
                                    emailText,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  onTap: () {
                                    nameController.text = customer.name;
                                    phoneController.text = customer.phone;
                                    emailController.text = customer.email ?? '';
                                    setState(() {
                                      suggestedCustomers = [];
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'e.g., +1234567890',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          keyboardType: TextInputType.phone,
                          maxLength: 15,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address (Optional)',
                            hintText: 'e.g., example@domain.com',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  );
                },
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
              GestureDetector(
                onTapDown: (_) => HapticFeedback.lightImpact(),
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    setState(() => isLoading = true);
                    HapticFeedback.lightImpact();
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final email = emailController.text.trim();
                    if (name.isNotEmpty && phone.isNotEmpty) {
                      final newCustomer = Customer(
                        name: name,
                        phone: phone,
                        email: email.isNotEmpty ? email : null,
                      );
                      dataController.addCustomer(newCustomer);
                      Navigator.pop(context);
                      _createInvoice(newCustomer);
                    } else {
                      Get.snackbar('Error', 'Name and phone number are required');
                    }
                    setState(() => isLoading = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ?  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onTertiary,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Add and Generate'),
                ),
              ),
            ],
          ),
        );
      },
    );

    // Dispose controllers and focus node
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    nameFocus.dispose();
  }

  Future<pw.Document> _generateInvoicePdf(Invoice invoice, String shopName, String customerName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  shopName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    font: pw.Font.courier(),
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Customer: $customerName',
                  style: pw.TextStyle(
                    fontSize: 18,
                    font: pw.Font.courier(),
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  DateFormat('EEE dd/MM/yyyy HH:mm').format(invoice.date),
                  style: pw.TextStyle(
                    fontSize: 18,
                    font: pw.Font.courier(),
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              ...invoice.services.asMap().entries.map((entry) {
                int idx = entry.key + 1;
                Map<String, dynamic> service = entry.value;
                String name = service['name'] as String;
                double price = service['price'] as double;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '$idx. $name',
                        style: pw.TextStyle(
                          fontSize: 18,
                          font: pw.Font.courier(),
                        ),
                      ),
                      pw.Text(
                        '$currencySymbol${formatPrice(price)}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          font: pw.Font.courier(),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      font: pw.Font.courier(),
                    ),
                  ),
                  pw.Text(
                    '$currencySymbol${formatPrice(_total)}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      font: pw.Font.courier(),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  '#${invoice.id}#',
                  style: pw.TextStyle(
                    fontSize: 16,
                    font: pw.Font.courier(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _showInvoiceDialog(Invoice invoice, Customer customer) async {
    final String shopName = storage.read('shopName') ?? 'My Barber Shop';

    final updatedInvoices = List<Invoice>.from(customer.invoices)..add(invoice);
    final updatedServices = List<String>.from(customer.services)
      ..addAll(invoice.services.map((service) => service['name'] as String));
    final updatedCustomer = Customer(
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      visitCount: customer.visitCount + 1,
      invoices: updatedInvoices,
      services: updatedServices,
    );

    bool isSaved = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          scrollable: true,
          title: Text(
            'Invoice',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  DateFormat('EEE dd/MM/yyyy HH:mm').format(invoice.date),
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Customer: ${customer.name}',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ...invoice.services.asMap().entries.map((entry) {
                  int idx = entry.key + 1;
                  Map<String, dynamic> service = entry.value;
                  String name = service['name'] as String;
                  double price = service['price'] as double;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$idx.$name',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '$currencySymbol${formatPrice(price)}',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL:',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '$currencySymbol${formatPrice(_total)}',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '#${invoice.id}#',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                dataController.addInvoice(invoice);
                if (!_isWalkIn) {
                  dataController.updateCustomer(updatedCustomer);
                  setState(() {
                    _selectedCustomer = updatedCustomer;
                  });
                }
                isSaved = true;
                setState(() {
                  _serviceSelection.updateAll((key, value) => false);
                  _total = 0.0;
                  customerNameController.clear();
                  _selectedCustomer = null;
                  _suggestedCustomers = [];
                });
                Navigator.pop(context);
                Get.snackbar(
                  'Success',
                  'Successfully generated and saved invoice',
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  colorText: Theme.of(context).colorScheme.onPrimary,
                );
              },
              child: Text(
                'Save',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save the invoice before printing
                dataController.addInvoice(invoice);
                if (!_isWalkIn) {
                  dataController.updateCustomer(updatedCustomer);
                  setState(() {
                    _selectedCustomer = updatedCustomer;
                  });
                }
                isSaved = true;
                setState(() {
                  _serviceSelection.updateAll((key, value) => false);
                  _total = 0.0;
                  customerNameController.clear();
                  _selectedCustomer = null;
                  _suggestedCustomers = [];
                });
                Get.snackbar(
                  'Success',
                  'Successfully generated and saved invoice',
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  colorText: Theme.of(context).colorScheme.onPrimary,
                );

                // Attempt to print
                try {
                  final pdf = await _generateInvoicePdf(invoice, shopName, customer.name);
                  await Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async => pdf.save(),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to print invoice: $e',
                    backgroundColor: Theme.of(context).colorScheme.error,
                    colorText: Theme.of(context).colorScheme.onError,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Print',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _createInvoice(Customer customer) {
    final selectedServices = dataController.services
        .where((service) => _serviceSelection[service.name] == true)
        .map((service) => {'name': service.name, 'price': service.price})
        .toList();

    final invoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: customer.name,
      services: selectedServices,
      total: _total,
      date: DateTime.now(),
    );

    _showInvoiceDialog(invoice, customer);
  }

  @override
  void dispose() {
    customerNameController.dispose();
    _customerNameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _updateServiceSelection();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Generate Invoice',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: customerNameController,
                focusNode: _customerNameFocus,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  hintText: 'Enter customer name',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _selectedCustomer != null
                      ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onChanged: _onCustomerNameChanged,
              ),
              if (_suggestedCustomers.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestedCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _suggestedCustomers[index];
                      final emailText = customer.email ?? 'No email provided';
                      return ListTile(
                        title: Text(
                          customer.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onTertiary,
                          ),
                        ),
                        subtitle: Text(
                          emailText,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onTertiary,
                          ),
                        ),
                        onTap: () => _selectCustomer(customer),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Select Services',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  return ListView.builder(
                    itemCount: dataController.services.length,
                    itemBuilder: (context, index) {
                      final service = dataController.services[index];
                      return Card(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: service.isAsset
                                ? Image.asset(
                              service.imagePath,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                                : Image.file(
                              File(service.imagePath),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            service.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onTertiary,
                            ),
                          ),
                          subtitle: Text(
                            'Category: ${service.category}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onTertiary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$currencySymbol${formatPrice(service.price)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onTertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Checkbox(
                                value: _serviceSelection[service.name] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    _serviceSelection[service.name] = value ?? false;
                                    _calculateTotal();
                                  });
                                },
                                activeColor: Theme.of(context).colorScheme.onTertiary,
                                checkColor: Theme.of(context).colorScheme.onSecondary,
                                focusColor:Theme.of(context).colorScheme.onTertiary,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.onTertiary,
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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (_selectedCustomer != null || customerNameController.text.trim().isNotEmpty)
                    Text(
                      '${_selectedCustomer?.name ?? customerNameController.text.trim()} bill is',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    'Total: $currencySymbol${_total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30,),
                    elevation: 5,
                  ),
                  onPressed: _generateInvoice,
                  child: Text(
                    'Generate Invoice',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onTertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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