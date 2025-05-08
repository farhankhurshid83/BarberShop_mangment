import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Classes/invoice.dart';
import '../Controllers/dataController.dart';
import '../Controllers/themeController.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  _SalesPageState createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final DataController dataController = Get.find<DataController>();
  final ThemeController themeController = Get.find<ThemeController>();
  String selectedFilter = 'Last 7 Days';
  DateTime? startDate;
  DateTime? endDate;
  int currentPage = 1;
  final int itemsPerPage = 10;

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

    List<Invoice> filteredInvoices;
    if (startDate == null || endDate == null) {
      filteredInvoices = dataController.invoices;
    } else {
      filteredInvoices = dataController.invoices.where((invoice) {
        return invoice.date.isAfter(startDate!.subtract(const Duration(milliseconds: 1))) &&
            invoice.date.isBefore(endDate!);
      }).toList();
    }

    filteredInvoices.sort((a, b) => b.date.compareTo(a.date));
    return filteredInvoices;
  }

  double _calculateTotalSales(List<Invoice> invoices) {
    return invoices.fold(0.0, (sum, invoice) => sum + invoice.total);
  }

  double _calculateAverageSale(List<Invoice> invoices) {
    if (invoices.isEmpty) return 0.0;
    return _calculateTotalSales(invoices) / invoices.length;
  }

  Map<String, List<Invoice>> _groupInvoicesByDate(List<Invoice> invoices) {
    final grouped = <String, List<Invoice>>{};
    for (var invoice in invoices) {
      String key;
      if (selectedFilter == 'Last 7 Days') {
        key = DateFormat('yyyy-MM-dd').format(invoice.date);
      } else {
        key = DateFormat('yyyy-MM').format(invoice.date);
      }
      grouped[key] = grouped[key] ?? [];
      grouped[key]!.add(invoice);
    }
    return grouped;
  }

  List<MapEntry<String, List<Invoice>>> _getPaginatedGroupedSales(Map<String, List<Invoice>> groupedSales) {
    final entries = groupedSales.entries.toList();
    entries.sort((a, b) => b.key.compareTo(a.key));
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return entries.sublist(
      startIndex,
      endIndex > entries.length ? entries.length : endIndex,
    );
  }

  List<BarChartGroupData> _buildBarChartData(Map<String, List<Invoice>> groupedSales) {
    final entries = groupedSales.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final sales = entry.value.value;
      final total = _calculateTotalSales(sales);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: total,
            color: Theme.of(context).colorScheme.secondary,
            width: 15,
          ),
        ],
      );
    }).toList();
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
          'Total Revenue',
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
                        currentPage = 1;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Obx(() {
                  final filteredInvoices = getFilteredInvoices();
                  final totalSales = _calculateTotalSales(filteredInvoices);
                  final averageSale = _calculateAverageSale(filteredInvoices);
                  final groupedSales = _groupInvoicesByDate(filteredInvoices);
                  final paginatedGroupedSales = _getPaginatedGroupedSales(groupedSales);

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Card(
                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Sales',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${themeController.currencySymbol.value}${totalSales.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Card(
                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Average Sale',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${themeController.currencySymbol.value}${averageSale.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (groupedSales.isNotEmpty)
                          Card(
                            color: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sales Trend',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 150,
                                    width: double.infinity,
                                    child: BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        barGroups: _buildBarChartData(groupedSales),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 30,
                                              getTitlesWidget: (value, meta) {
                                                final entries = groupedSales.entries.toList()
                                                  ..sort((a, b) => a.key.compareTo(b.key));
                                                if (value.toInt() >= 0 && value.toInt() < entries.length) {
                                                  final date = entries[value.toInt()].key;
                                                  if (selectedFilter == 'Last 7 Days') {
                                                    return Text(
                                                      DateFormat('dd/MM').format(DateTime.parse(date)),
                                                      style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onSurface,
                                                        fontSize: 12,
                                                      ),
                                                    );
                                                  } else {
                                                    // Parse the yyyy-MM format manually
                                                    final parts = date.split('-');
                                                    final year = int.parse(parts[0]);
                                                    final month = int.parse(parts[1]);
                                                    final dateTime = DateTime(year, month);
                                                    return Text(
                                                      DateFormat('MM/yy').format(dateTime),
                                                      style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onSurface,
                                                        fontSize: 12,
                                                      ),
                                                    );
                                                  }
                                                }
                                                return const Text('');
                                              },
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          topTitles: AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          rightTitles: AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        gridData: FlGridData(show: false),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          'Sales Breakdown',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 20),
                        groupedSales.isEmpty
                            ? Center(
                          child: Text(
                            'No sales available.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                            : Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                              child: ListView.builder(
                                itemCount: paginatedGroupedSales.length,
                                itemBuilder: (context, index) {
                                  final entry = paginatedGroupedSales[index];
                                  final date = entry.key;
                                  final sales = entry.value;
                                  final total = _calculateTotalSales(sales);
                                  return Card(
                                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
                                    margin: const EdgeInsets.only(bottom: 16.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                selectedFilter == 'Last 7 Days'
                                                    ? DateFormat('yyyy-MM-dd').format(DateTime.parse(date))
                                                    : () {
                                                  final parts = date.split('-');
                                                  final year = int.parse(parts[0]);
                                                  final month = int.parse(parts[1]);
                                                  return DateFormat('MMMM yyyy').format(DateTime(year, month));
                                                }(),
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onTertiary,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${sales.length} Sale${sales.length > 1 ? 's' : ''}',
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onTertiary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${themeController.currencySymbol.value}${total.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onTertiary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (groupedSales.length > itemsPerPage)
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
                                    'Page $currentPage of ${(groupedSales.length / itemsPerPage).ceil()}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_forward,
                                      color: currentPage == (groupedSales.length / itemsPerPage).ceil()
                                          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                    onPressed: currentPage == (groupedSales.length / itemsPerPage).ceil()
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
                        ),
                      ],
                    ),
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