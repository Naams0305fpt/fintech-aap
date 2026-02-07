import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Statistics screen with charts
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final expenseByCategory = provider.expenseByCategory;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Thống kê',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildMonthSelector(provider),
                    ],
                  ),
                ),

                // Summary cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Thu nhập',
                          provider.monthlyIncome,
                          Icons.trending_up,
                          AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Chi tiêu',
                          provider.monthlyExpense,
                          Icons.trending_down,
                          AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Balance card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildBalanceCard(provider),
                ),

                const SizedBox(height: 24),

                // Pie chart section
                if (expenseByCategory.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Chi tiêu theo danh mục',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: _buildPieChart(expenseByCategory, provider),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryLegend(expenseByCategory, provider),
                ] else
                  _buildNoDataCard('Chưa có chi tiêu trong tháng này'),

                const SizedBox(height: 24),

                // Daily spending bar chart
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Chi tiêu theo ngày',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                if (provider.monthlyTransactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 200,
                      child: _buildBarChart(provider),
                    ),
                  )
                else
                  _buildNoDataCard('Chưa có giao dịch trong tháng này'),

                const SizedBox(height: 24),

                // Top spending categories
                if (expenseByCategory.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Chi tiêu nhiều nhất',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTopCategoriesList(expenseByCategory, provider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector(AppProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => provider.previousMonth(),
          iconSize: 20,
        ),
        GestureDetector(
          onTap: () => _selectMonth(context, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              DateFormatter.formatMonthYear(provider.selectedMonth),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: provider.selectedMonth.isBefore(DateTime.now())
              ? () => provider.nextMonth()
              : null,
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(AppProvider provider) {
    final balance = provider.monthlyBalance;
    final isPositive = balance >= 0;
    final savingsRate = provider.monthlyIncome > 0
        ? (balance / provider.monthlyIncome * 100).clamp(0, 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [AppTheme.success.withAlpha(51), AppTheme.success.withAlpha(26)]
              : [AppTheme.danger.withAlpha(51), AppTheme.danger.withAlpha(26)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPositive ? 'Còn dư' : 'Thiếu hụt',
                  style: TextStyle(
                    color: isPositive ? AppTheme.success : AppTheme.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(balance.abs()),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? AppTheme.success : AppTheme.danger,
                  ),
                ),
              ],
            ),
          ),
          if (isPositive && savingsRate > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(51),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '${savingsRate.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                  const Text(
                    'tiết kiệm',
                    style: TextStyle(fontSize: 11, color: AppTheme.success),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPieChart(
    Map<String, double> expenseByCategory,
    AppProvider provider,
  ) {
    final total = expenseByCategory.values.fold(0.0, (a, b) => a + b);
    final entries = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final categoryId = entry.value.key;
          final amount = entry.value.value;
          final category = provider.getCategory(categoryId);
          final isTouched = index == _touchedIndex;
          final percentage = (amount / total * 100);

          return PieChartSectionData(
            color: category != null
                ? Color(category.colorValue)
                : AppTheme.textMuted,
            value: amount,
            title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
            radius: isTouched ? 60 : 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryLegend(
    Map<String, double> expenseByCategory,
    AppProvider provider,
  ) {
    final entries = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = expenseByCategory.values.fold(0.0, (a, b) => a + b);

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: entries.take(6).map((entry) {
        final category = provider.getCategory(entry.key);
        final percentage = (entry.value / total * 100);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: category != null
                    ? Color(category.colorValue)
                    : AppTheme.textMuted,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${category?.name ?? "Khác"} (${percentage.toStringAsFixed(0)}%)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBarChart(AppProvider provider) {
    // Get daily expenses for current month
    final transactions = provider.monthlyTransactions
        .where((t) => t.isExpense && t.isConfirmed)
        .toList();

    if (transactions.isEmpty) {
      return _buildNoDataCard('Chưa có chi tiêu trong tháng này');
    }

    // Group by day
    final Map<int, double> dailyExpenses = {};
    for (final t in transactions) {
      final day = t.date.day;
      dailyExpenses[day] = (dailyExpenses[day] ?? 0) + t.amount;
    }

    final maxExpense = dailyExpenses.values.fold(0.0, (a, b) => a > b ? a : b);
    final daysInMonth = DateTime(
      provider.selectedMonth.year,
      provider.selectedMonth.month + 1,
      0,
    ).day;

    // Show last 14 days or all days if less
    final startDay = daysInMonth > 14 ? daysInMonth - 13 : 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxExpense * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = startDay + groupIndex;
              final amount = dailyExpenses[day] ?? 0;
              return BarTooltipItem(
                'Ngày $day\n${CurrencyFormatter.formatCompact(amount)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
              getTitlesWidget: (value, meta) {
                final day = startDay + value.toInt();
                if (day % 2 == 0 || daysInMonth <= 10) {
                  return Text(
                    '$day',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 20,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text(
                  CurrencyFormatter.formatCompact(value),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 50,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: AppTheme.textMuted.withAlpha(26), strokeWidth: 1),
        ),
        barGroups: List.generate(daysInMonth - startDay + 1, (index) {
          final day = startDay + index;
          final amount = dailyExpenses[day] ?? 0;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: amount,
                color: amount > 0 ? AppTheme.danger : AppTheme.surfaceLight,
                width: daysInMonth > 20 ? 8 : 12,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTopCategoriesList(
    Map<String, double> expenseByCategory,
    AppProvider provider,
  ) {
    final entries = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (sum, e) => sum + e.value);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: entries.take(5).map((entry) {
          final category = provider.getCategory(entry.key);
          final percentage = entry.value / total;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: category != null
                        ? Color(category.colorValue).withAlpha(51)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      category?.icon ?? '💰',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.name ?? 'Không phân loại',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: AppTheme.surface,
                          valueColor: AlwaysStoppedAnimation(
                            category != null
                                ? Color(category.colorValue)
                                : AppTheme.textMuted,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatCompact(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoDataCard(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.insert_chart_outlined,
              size: 48,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context, AppProvider provider) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: provider.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (selected != null) {
      provider.setSelectedMonth(DateTime(selected.year, selected.month));
    }
  }
}
