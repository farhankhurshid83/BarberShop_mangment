import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../Classes/expense.dart';
import '../../../Classes/invoice.dart';
import '../../../Controllers/themeController.dart';

class TodaysSummaryWidget extends StatelessWidget {
  final List<Invoice> invoices;
  final List<Expense> expenses;

  const TodaysSummaryWidget({
    super.key,
    required this.invoices,
    required this.expenses,
  });

  // Aggregate income and expenses for all unique days
  Map<String, Map<String, double>> _aggregateData() {
    final formatter = DateFormat('MMM dd');
    final data = <String, Map<String, double>>{};

    for (var invoice in invoices) {
      try {
        final dayKey = formatter.format(invoice.date);
        data.putIfAbsent(dayKey, () => {'income': 0.0, 'expenses': 0.0});
        data[dayKey]!['income'] = (data[dayKey]!['income']! + invoice.total);
      } catch (e) {}
    }

    for (var expense in expenses) {
      try {
        final dayKey = formatter.format(expense.date);
        data.putIfAbsent(dayKey, () => {'income': 0.0, 'expenses': 0.0});
        data[dayKey]!['expenses'] = (data[dayKey]!['expenses']! + expense.amount);
      } catch (e) {}
    }

    return data;
  }

  // Calculate the maximum Y value for the chart
  double _calculateMaxY(Map<String, Map<String, double>> data) {
    double maxY = 0.0;
    for (var dayData in data.values) {
      final income = dayData['income'] ?? 0.0;
      final expenses = dayData['expenses'] ?? 0.0;
      maxY = maxY < income ? income : maxY;
      maxY = maxY < expenses ? expenses : maxY;
    }
    return maxY == 0.0 ? 100.0 : maxY * 1.1;
  }

  // Helper function to format numbers (e.g., 1500 -> 1.5k)
  String _formatNumber(double value) {
    if (value >= 1000) {
      final kValue = value / 1000;
      // Remove trailing zeros for whole numbers (e.g., 1.0k -> 1k)
      return kValue == kValue.roundToDouble()
          ? '${kValue.toInt()}k'
          : '${kValue.toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    final data = _aggregateData();
    final days = data.keys.toList()..sort();

    if (days.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.secondary,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No data available',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    final maxY = _calculateMaxY(data);

    return Card(
      color: Theme.of(context).colorScheme.secondary,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Overview',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipColor: (_) => Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      tooltipBorder: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = days[group.x];
                        final type = rodIndex == 0 ? 'Income' : 'Expenses';
                        final formattedValue = _formatNumber(rod.toY);
                        return BarTooltipItem(
                          '$day $type\n${themeController.currencySymbol.value}$formattedValue',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < days.length) {
                            final day = days[value.toInt()];
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Transform.rotate(
                                angle: -45 * 3.14159 / 180,
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final formattedValue = _formatNumber(value);
                          return Obx(() => Text(
                            '${themeController.currencySymbol.value}$formattedValue',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(days.length, (index) {
                    final dayData = data[days[index]]!;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: dayData['income'] ?? 0.0,
                          color: Theme.of(context).colorScheme.primary,
                          width: 8,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: dayData['expenses'] ?? 0.0,
                          color: Theme.of(context).colorScheme.error,
                          width: 8,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                      showingTooltipIndicators: [],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  Theme.of(context).colorScheme.primary,
                  'Income',
                  Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 20),
                _buildLegendItem(
                  Theme.of(context).colorScheme.error,
                  'Expenses',
                  Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, Color textColor) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}