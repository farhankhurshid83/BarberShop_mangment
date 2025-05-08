import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../Classes/invoice.dart';
import '../Controllers/dataController.dart';
import '../Controllers/themeController.dart';
import 'package:intl/intl.dart';

class AllInvoicesScreen extends StatefulWidget {
  const AllInvoicesScreen({super.key});

  @override
  _AllInvoicesScreenState createState() => _AllInvoicesScreenState();
}

class _AllInvoicesScreenState extends State<AllInvoicesScreen> {
  final DataController dataController = Get.find<DataController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final GetStorage storage = GetStorage(); // Initialize GetStorage
  String selectedFilter = 'All Time'; // Default filter
  DateTime? startDate;
  DateTime? endDate;
  int currentPage = 1; // Current page for pagination
  final int invoicesPerPage = 10; // Number of invoices per page

  // Filter options
  final List<String> filterOptions = [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Past Month',
    'All Time'
  ];

  // Filter invoices based on selected date range
  List<Invoice> getFilteredInvoices() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (selectedFilter == 'Today') {
      startDate = today;
      endDate = today.add(const Duration(days: 1));
    } else if (selectedFilter == 'Yesterday') {
      startDate = today.subtract(const Duration(days: 1));
      endDate = today;
    } else if (selectedFilter == 'Last 7 Days') {
      startDate = today.subtract(const Duration(days: 7));
      endDate = now;
    } else if (selectedFilter == 'Last 30 Days') {
      startDate = today.subtract(const Duration(days: 30));
      endDate = now;
    } else if (selectedFilter == 'This Month') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = now;
    } else if (selectedFilter == 'Past Month') {
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      startDate = lastMonth;
      endDate = DateTime(now.year, now.month, 1);
    } else {
      // All Time
      startDate = null;
      endDate = null;
    }

    List<Invoice> filteredInvoices;
    if (startDate == null || endDate == null) {
      filteredInvoices = dataController.invoices as List<Invoice>;
    } else {
      filteredInvoices = dataController.invoices.where((invoice) {
        return invoice.date.isAfter(startDate!.subtract(const Duration(milliseconds: 1))) &&
            invoice.date.isBefore(endDate!);
      }).cast<Invoice>().toList();
    }

    // Sort invoices by date in descending order (latest first)
    filteredInvoices.sort((a, b) => b.date.compareTo(a.date));
    return filteredInvoices;
  }

  // Get paginated invoices
  List<Invoice> getPaginatedInvoices() {
    final filteredInvoices = getFilteredInvoices();
    final startIndex = (currentPage - 1) * invoicesPerPage;
    final endIndex = startIndex + invoicesPerPage;
    return filteredInvoices.sublist(
      startIndex,
      endIndex > filteredInvoices.length ? filteredInvoices.length : endIndex,
    );
  }

  // Delete an invoice
  void _deleteInvoice(Invoice invoice) {
    dataController.removeInvoice(invoice.id); // Assuming DataController has a removeInvoice method
    Get.back(); // Close the dialog
    Get.snackbar(
      'Success',
      'Invoice deleted successfully',
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
      colorText: Theme.of(context).colorScheme.onPrimary,
    );
    // Adjust pagination if needed
    final filteredInvoices = getFilteredInvoices();
    if (filteredInvoices.isEmpty || (currentPage - 1) * invoicesPerPage >= filteredInvoices.length) {
      setState(() {
        currentPage = (filteredInvoices.length / invoicesPerPage).ceil();
        if (currentPage < 1) currentPage = 1;
      });
    }
  }

  // Show full invoice in a dialog
  void _showInvoiceDialog(Invoice invoice) {
    final String shopName = storage.read('shopName') ?? 'My Barber Shop'; // Fetch shop name
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            shopName, // Use fetched shop name
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
                Text(
                  'Mon ${DateFormat('dd/MM/yyyy HH:mm').format(invoice.date)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Customer: ${invoice.customerName}', // Add customer name
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const Divider(),
                ...invoice.services.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final service = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$index. ${service['name']}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${themeController.currencySymbol.value}${service['price'].toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL:',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${themeController.currencySymbol.value}${invoice.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Center(
                  child: Text(
                    '#${invoice.id}#',
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
                Get.defaultDialog(
                  title: 'Delete Invoice',
                  middleText: 'Are you sure you want to delete this invoice?',
                  textConfirm: 'Yes',
                  textCancel: 'No',
                  confirmTextColor: Theme.of(context).colorScheme.onPrimary,
                  onConfirm: () => _deleteInvoice(invoice),
                  onCancel: () {},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Bills',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by Date:',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton<String>(
                    value: selectedFilter,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    items: filterOptions.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(
                          option,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedFilter = newValue!;
                        currentPage = 1; // Reset to first page on filter change
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Obx(() {
                  final filteredInvoices = getFilteredInvoices();
                  final paginatedInvoices = getPaginatedInvoices();
                  return paginatedInvoices.isEmpty
                      ? Center(
                    child: Text(
                      'No invoices available.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                      : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = paginatedInvoices[index];
                            return Card(
                              color: Theme.of(context).colorScheme.secondary,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  invoice.customerName,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onTertiary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                trailing: Text(
                                  '${themeController.currencySymbol.value}${invoice.total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onTap: () => _showInvoiceDialog(invoice),
                              ),
                            );
                          },
                        ),
                      ),
                      if (filteredInvoices.length > invoicesPerPage) // Show pagination if needed
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: currentPage == 1
                                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              onPressed: currentPage == 1
                                  ? null
                                  : () {
                                setState(() {
                                  currentPage--;
                                });
                              },
                            ),
                            Text(
                              'Page $currentPage of ${(filteredInvoices.length / invoicesPerPage).ceil()}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.arrow_forward,
                                color: currentPage == (filteredInvoices.length / invoicesPerPage).ceil()
                                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              onPressed: currentPage == (filteredInvoices.length / invoicesPerPage).ceil()
                                  ? null
                                  : () {
                                setState(() {
                                  currentPage++;
                                });
                              },
                            ),
                          ],
                        ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}