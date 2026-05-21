import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../themes/app_theme.dart';

enum _ReportMode { daily, monthly, yearly }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportMode _mode = _ReportMode.daily;

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child!),
          child: Column(
            children: [
            // ── Filter buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: _ReportMode.values.map((mode) {
                  final labels = {
                    _ReportMode.daily: 'Daily',
                    _ReportMode.monthly: 'Monthly',
                    _ReportMode.yearly: 'Yearly',
                  };
                  final selected = _mode == mode;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mode = mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primaryColor
                                : AppTheme.borderColor,
                          ),
                        ),
                        child: Text(
                          labels[mode]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? Colors.black
                                : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
            // ── Report content ──
            Expanded(
              child: _PeriodReport(provider: provider, mode: _mode),
            ),
          ],
        ),
        );
      },
    );
  }
}

// ─── Period Report ────────────────────────────────────────────────────────────

class _PeriodReport extends StatelessWidget {
  final ExpenseProvider provider;
  final _ReportMode mode;

  const _PeriodReport({required this.provider, required this.mode});

  String _keyFor(DateTime date) {
    switch (mode) {
      case _ReportMode.daily:
        return DateFormat('MMM d, yyyy').format(date);
      case _ReportMode.monthly:
        return DateFormat('MMM yyyy').format(date);
      case _ReportMode.yearly:
        return DateFormat('yyyy').format(date);
    }
  }

  String get _breakdownTitle {
    switch (mode) {
      case _ReportMode.daily:
        return 'Daily Breakdown';
      case _ReportMode.monthly:
        return 'Monthly Breakdown';
      case _ReportMode.yearly:
        return 'Yearly Breakdown';
    }
  }

  String get _chartTitle {
    switch (mode) {
      case _ReportMode.daily:
        return 'Last 7 Days';
      case _ReportMode.monthly:
        return 'Last 6 Months';
      case _ReportMode.yearly:
        return 'All Years';
    }
  }

  Map<String, double> _getTotals() {
    final Map<String, double> totals = {};
    for (final expense in provider.expenses) {
      final key = _keyFor(expense.date);
      totals[key] = (totals[key] ?? 0) + expense.amount;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) {
        try {
          DateTime da, db;
          switch (mode) {
            case _ReportMode.daily:
              da = DateFormat('MMM d, yyyy').parse(a.key);
              db = DateFormat('MMM d, yyyy').parse(b.key);
              break;
            case _ReportMode.monthly:
              da = DateFormat('MMM yyyy').parse(a.key);
              db = DateFormat('MMM yyyy').parse(b.key);
              break;
            case _ReportMode.yearly:
              da = DateTime(int.parse(a.key));
              db = DateTime(int.parse(b.key));
              break;
          }
          return db.compareTo(da); // newest first
        } catch (_) {
          return 0;
        }
      });
    return Map.fromEntries(entries);
  }

  String _shortLabel(String key) {
    switch (mode) {
      case _ReportMode.daily:
        return key.split(',').first; // "May 3, 2026" → "May 3"
      case _ReportMode.monthly:
        return key.split(' ').first; // "May 2026" → "May"
      case _ReportMode.yearly:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = _getTotals();

    if (totals.isEmpty) {
      return const Center(
        child: Text('No data yet',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      );
    }

    final entries = totals.entries.toList();
    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // Chart: last N entries, reversed to oldest→newest
    final chartCount = mode == _ReportMode.daily
        ? 7
        : mode == _ReportMode.monthly
            ? 6
            : entries.length;
    final chartSlice =
        entries.length > chartCount ? entries.sublist(0, chartCount) : entries;
    final chartData = chartSlice.reversed.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title
          Text(
            _chartTitle,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Bar chart
          Container(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(
                      show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= chartData.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _shortLabel(chartData[idx].key),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55,
                        getTitlesWidget: (val, meta) => Text(
                          'Rs ${val.toInt()}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    chartData.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: chartData[i].value,
                          color: AppTheme.primaryColor,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Breakdown title
          Text(
            _breakdownTitle,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Breakdown list
          ...List.generate(entries.length, (index) {
            final entry = entries[index];
            final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Rs ${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: AppTheme.borderColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
