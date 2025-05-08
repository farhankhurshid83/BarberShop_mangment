import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../Classes/expense.dart';
import '../Controllers/dataController.dart';
import '../Controllers/themeController.dart';
import 'package:intl/intl.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  _ExpensesPageState createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final DataController dataController = Get.find<DataController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String selectedFilter = 'All Time';
  DateTime? startDate;
  DateTime? endDate;

  final List<String> filterOptions = [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Past Month',
    'All Time',
  ];

  // List of predefined categories
  final List<String> _categories = [
    'Utilities',
    'Supplies',
    'Rent',
    'Salaries',
    'Maintenance',
    'Other',
  ];

  List<Expense> getFilteredExpenses() {
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
      startDate = DateTime(now.year, now.month - 1, 1);
      endDate = DateTime(now.year, now.month, 1);
    } else {
      startDate = null;
      endDate = null;
    }

    if (startDate == null || endDate == null) {
      return dataController.expenses;
    }

    return dataController.expenses.where((expense) {
      return expense.date.isAfter(
        startDate!.subtract(const Duration(milliseconds: 1)),
      ) &&
          expense.date.isBefore(endDate!);
    }).toList();
  }

  double _calculateTotalExpenses(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Delete an expense
  void _deleteExpense(Expense expense) {
    dataController.removeExpense(expense.id);
    Get.back(); // Close the confirmation dialog
    Navigator.pop(context); // Close the expense details dialog
    Get.snackbar(
      'Success',
      'Expense deleted successfully',
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
      colorText: Theme.of(context).colorScheme.onPrimary,
    );
  }

  // Show add expense dialog
  void _showAddExpenseDialog() {
    String? selectedCategory;
    bool isLoading = false;

    // Clear controllers before showing dialog
    _descriptionController.clear();
    _amountController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.9,
              ),
              child: AlertDialog(
                backgroundColor: Theme.of(dialogContext).colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(
                  'Add Expense',
                  style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.onSurface,
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
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'e.g., Electricity Bill',
                          labelStyle: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          hintStyle: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(dialogContext).colorScheme.secondary,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Theme.of(dialogContext).colorScheme.surface.withValues(alpha: 0.9),
                        ),
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.onSurface,
                        ),
                        maxLength: 50,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: 'e.g., 100.00',
                          labelStyle: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          hintStyle: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(dialogContext).colorScheme.secondary,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Theme.of(dialogContext).colorScheme.surface.withValues(alpha: 0.9),
                        ),
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.onSurface,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Category (Optional)',
                          hintText: 'Select Category',
                          labelStyle: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          hintStyle: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(dialogContext).colorScheme.secondary,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Theme.of(dialogContext).colorScheme.surface.withValues(alpha: 0.9),
                        ),
                        value: selectedCategory,
                        hint: Text(
                          'Select Category',
                          style: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        items: _categories
                            .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(
                              color: Theme.of(dialogContext).colorScheme.onSurface,
                            ),
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.onSurface,
                        ),
                        dropdownColor: Theme.of(dialogContext).colorScheme.surface,
                        isExpanded: true,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _descriptionController.clear();
                      _amountController.clear();
                      setState(() => selectedCategory = null);
                      Navigator.pop(dialogContext);
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTapDown: (_) => HapticFeedback.lightImpact(),
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                        setState(() => isLoading = true);
                        HapticFeedback.lightImpact();
                        final description = _descriptionController.text;
                        final amountText = _amountController.text;

                        if (description.isNotEmpty && amountText.isNotEmpty) {
                          final amount = double.tryParse(amountText);
                          if (amount != null) {
                            dataController.addExpense(Expense(
                              id: DateTime.now().millisecondsSinceEpoch,
                              description: description,
                              amount: amount,
                              date: DateTime.now(),
                              category: selectedCategory ?? 'Uncategorized',
                            ));
                            _descriptionController.clear();
                            _amountController.clear();
                            setState(() => selectedCategory = null);
                            Navigator.pop(dialogContext);
                            Get.snackbar(
                              'Success',
                              'Expense added successfully',
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                              colorText: Theme.of(context).colorScheme.onPrimary,
                            );
                          } else {
                            setState(() => isLoading = false);
                            Get.snackbar(
                              'Error',
                              'Please enter a valid amount',
                              backgroundColor: Theme.of(dialogContext).colorScheme.error,
                              colorText: Theme.of(dialogContext).colorScheme.onError,
                            );
                          }
                        } else {
                          setState(() => isLoading = false);
                          Get.snackbar(
                            'Error',
                            'Please fill in all required fields (Description and Amount)',
                            backgroundColor: Theme.of(dialogContext).colorScheme.error,
                            colorText: Theme.of(dialogContext).colorScheme.onError,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(dialogContext).colorScheme.secondary,
                        foregroundColor: Theme.of(dialogContext).colorScheme.onTertiary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: isLoading
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Theme.of(dialogContext).colorScheme.onTertiary,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text('Add'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Show edit expense dialog
  void _showEditExpenseDialog(Expense expense) {
    final editDescriptionController = TextEditingController(text: expense.description);
    final editAmountController = TextEditingController(text: expense.amount.toString());
    String? editSelectedCategory = expense.category == 'Uncategorized' ? null : expense.category;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                'Edit Expense',
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
                    TextFormField(
                      controller: editDescriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: editAmountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Category (Optional)',
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
                      value: editSelectedCategory,
                      hint: Text(
                        'Select Category',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      items: _categories
                          .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          editSelectedCategory = value;
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
                    final description = editDescriptionController.text;
                    final amountText = editAmountController.text;

                    if (description.isNotEmpty && amountText.isNotEmpty) {
                      final amount = double.tryParse(amountText);
                      if (amount != null) {
                        dataController.updateExpense(
                          expense.id,
                          Expense(
                            id: expense.id,
                            description: description,
                            amount: amount,
                            date: expense.date,
                            category: editSelectedCategory ?? 'Uncategorized',
                          ),
                        );
                        Navigator.pop(context); // Close the edit dialog
                        Navigator.pop(context); // Close the expense details dialog
                        Get.snackbar(
                          'Success',
                          'Expense updated successfully',
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                          colorText: Theme.of(context).colorScheme.onPrimary,
                        );
                      } else {
                        Get.snackbar(
                          'Error',
                          'Please enter a valid amount',
                          backgroundColor: Theme.of(context).colorScheme.error,
                          colorText: Theme.of(context).colorScheme.onError,
                        );
                      }
                    } else {
                      Get.snackbar(
                        'Error',
                        'Please fill in all required fields (Description and Amount)',
                        backgroundColor: Theme.of(context).colorScheme.error,
                        colorText: Theme.of(context).colorScheme.onError,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show expense details in a dialog
  void _showExpenseDialog(Expense expense) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Expense Details',
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
                  'Description: ${expense.description}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: ${themeController.currencySymbol.value}${expense.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Category: ${expense.category}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(expense.date)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const Divider(),
                Center(
                  child: Text(
                    '#${expense.id}#',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                  onPressed: () => _showEditExpenseDialog(expense),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 3),
                ElevatedButton(
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'Delete Expense',
                      middleText: 'Are you sure you want to delete this expense?',
                      textConfirm: 'Yes',
                      textCancel: 'No',
                      confirmTextColor: Theme.of(context).colorScheme.onPrimary,
                      onConfirm: () => _deleteExpense(expense),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Total Costs',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
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
                      items: filterOptions.map((option) {
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
                      onChanged: (newValue) {
                        setState(() {
                          selectedFilter = newValue!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Obx(() {
                  final filteredExpenses = getFilteredExpenses();
                  final totalExpenses = _calculateTotalExpenses(filteredExpenses);
                  return Column(
                    children: [
                      Card(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Total Expenses',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onTertiary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  '${themeController.currencySymbol.value}${totalExpenses.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onTertiary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      filteredExpenses.isEmpty
                          ? Center(
                        child: Text(
                          'No expenses available.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                          : SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: ListView.builder(
                          itemCount: filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = filteredExpenses[index];
                            return Card(
                              color: Theme.of(context).colorScheme.secondary,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  expense.description,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onTertiary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'Date: ${DateFormat('yyyy-MM-dd').format(expense.date)}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  '${themeController.currencySymbol.value}${expense.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onTertiary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _showExpenseDialog(expense),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: _showAddExpenseDialog,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onTertiary,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}