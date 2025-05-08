import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../Classes/expense.dart';
import '../Classes/invoice.dart';
import '../Controllers/dataController.dart';
import '../Controllers/themeController.dart';
import 'package:intl/intl.dart';

class FinancialOverviewPage extends StatefulWidget {
  const FinancialOverviewPage({super.key});

  @override
  _FinancialOverviewPageState createState() => _FinancialOverviewPageState();
}

class _FinancialOverviewPageState extends State<FinancialOverviewPage> {
  final DataController dataController = Get.find<DataController>();
  final ThemeController themeController = Get.find<ThemeController>(); // Add ThemeController
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
    'All Time'
  ];

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
      startDate = null;
      endDate = null;
    }

    if (startDate == null || endDate == null) {
      return dataController.invoices;
    }

    return dataController.invoices.where((invoice) {
      return invoice.date.isAfter(startDate!.subtract(const Duration(milliseconds: 1))) &&
          invoice.date.isBefore(endDate!);
    }).toList();
  }

  List<Expense> getFilteredExpenses() {
    if (startDate == null || endDate == null) {
      return dataController.expenses;
    }

    return dataController.expenses.where((expense) {
      return expense.date.isAfter(startDate!.subtract(const Duration(milliseconds: 1))) &&
          expense.date.isBefore(endDate!);
    }).toList();
  }

  double _calculateTotalSales(List<Invoice> invoices) {
    return invoices.fold(0.0, (sum, invoice) => sum + invoice.total);
  }

  double _calculateTotalExpenses(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double _calculateProfitLoss(List<Invoice> invoices, List<Expense> expenses) {
    return _calculateTotalSales(invoices) - _calculateTotalExpenses(expenses);
  }

  List<FlSpot> getSalesSpots(List<Invoice> invoices) {
    if (startDate == null || endDate == null) {
      return [FlSpot(0, 0)]; // Default spot for empty data
    }

    final days = endDate!.difference(startDate!).inDays + 1;
    final List<FlSpot> spots = [];
    for (int i = 0; i < days; i++) {
      final day = startDate!.add(Duration(days: i));
      final dailySales = invoices
          .where((invoice) =>
      invoice.date.day == day.day &&
          invoice.date.month == day.month &&
          invoice.date.year == day.year)
          .fold(0.0, (sum, invoice) => sum + invoice.total);
      spots.add(FlSpot(i.toDouble(), dailySales));
    }
    return spots;
  }

  List<FlSpot> getExpensesSpots(List<Expense> expenses) {
    if (startDate == null || endDate == null) {
      return [FlSpot(0, 0)]; // Default spot for empty data
    }

    final days = endDate!.difference(startDate!).inDays + 1;
    final List<FlSpot> spots = [];
    for (int i = 0; i < days; i++) {
      final day = startDate!.add(Duration(days: i));
      final dailyExpenses = expenses
          .where((expense) =>
      expense.date.day == day.day &&
          expense.date.month == day.month &&
          expense.date.year == day.year)
          .fold(0.0, (sum, expense) => sum + expense.amount);
      spots.add(FlSpot(i.toDouble(), dailyExpenses));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Financial Overview',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
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
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Obx(() {
                  final filteredInvoices = getFilteredInvoices();
                  final filteredExpenses = getFilteredExpenses();
                  final totalSales = _calculateTotalSales(filteredInvoices);
                  final totalExpenses = _calculateTotalExpenses(filteredExpenses);
                  final profitLoss = _calculateProfitLoss(filteredInvoices, filteredExpenses);
                  final isProfit = profitLoss >= 0;

                  final salesSpots = getSalesSpots(filteredInvoices);
                  final expensesSpots = getExpensesSpots(filteredExpenses);
                  final maxY = (salesSpots + expensesSpots)
                      .map((spot) => spot.y)
                      .fold(0.0, (a, b) => a > b ? a : b);
                  final chartDays = (startDate != null && endDate != null)
                      ? endDate!.difference(startDate!).inDays + 1
                      : 1;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Total Sales',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    '${themeController.currencySymbol.value}${totalSales.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Total Expenses',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
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
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                              color: Colors.grey,
                              height: 20,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    isProfit ? 'Profit' : 'Loss',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    '${themeController.currencySymbol.value}${profitLoss.abs().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: isProfit ? Colors.green : Theme.of(context).colorScheme.error,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (selectedFilter != 'All Time' &&
                          salesSpots.isNotEmpty &&
                          expensesSpots.isNotEmpty) ...[
                        Text(
                          'Sales vs Expenses Trend',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 300,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                horizontalInterval: maxY > 0 ? maxY / 5 : 20,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                                  strokeWidth: 1,
                                ),
                                getDrawingVerticalLine: (value) => FlLine(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    interval: maxY > 0 ? maxY / 5 : 20,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '${themeController.currencySymbol.value}${value.toInt()}',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      if (chartDays <= 1) {
                                        return Text(
                                          DateFormat('dd/MM').format(startDate!),
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                            fontSize: 12,
                                          ),
                                        );
                                      }
                                      if (value.toInt() % (chartDays ~/ 5 == 0 ? 1 : chartDays ~/ 5) == 0) {
                                        final date = startDate!.add(Duration(days: value.toInt()));
                                        return Text(
                                          DateFormat('dd/MM').format(date),
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                            fontSize: 12,
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              minX: 0,
                              maxX: chartDays <= 1 ? 1 : (chartDays - 1).toDouble(),
                              minY: 0,
                              maxY: maxY > 0 ? maxY * 1.2 : 100,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: salesSpots,
                                  isCurved: true,
                                  color: Colors.green,
                                  barWidth: 3,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                      radius: 4,
                                      color: Colors.green,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.green.withValues(alpha: 0.2),
                                  ),
                                ),
                                LineChartBarData(
                                  spots: expensesSpots,
                                  isCurved: true,
                                  color: Theme.of(context).colorScheme.error,
                                  barWidth: 3,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                      radius: 4,
                                      color: Theme.of(context).colorScheme.error,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
                                  ),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipBorder: BorderSide(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  tooltipRoundedRadius: 8, // Set rounded corners for tooltip
                                  getTooltipColor: (_) => Theme.of(context).colorScheme.surface.withValues(alpha: 0.9), // Set background color
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final date = startDate!.add(Duration(days: spot.x.toInt()));
                                      return LineTooltipItem(
                                        spot.barIndex == 0
                                            ? 'Sales: ${themeController.currencySymbol.value}${spot.y.toStringAsFixed(2)}\n'
                                            : 'Expenses: ${themeController.currencySymbol.value}${spot.y.toStringAsFixed(2)}\n',
                                        TextStyle(
                                          color: spot.barIndex == 0 ? Colors.green : Theme.of(context).colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: DateFormat('dd/MM/yyyy').format(date),
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList();
                                  },
                                ),
                                handleBuiltInTouches: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sales',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Expenses',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        'Sales',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Total Sales',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '${themeController.currencySymbol.value}${totalSales.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Purchases (Expenses)',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Total Expenses',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
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
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
    );
  }
}