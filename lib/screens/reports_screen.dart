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
  String _typeFilter = 'All'; // 'All', 'Expense', 'Income'

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) => Opacity(opacity: value, child: child!),
          child: Column(
            children: [
              // ── Type Filter (All, Expense, Income) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: ['All', 'Expense', 'Income'].map((type) {
                    final selected = _typeFilter == type;
                    Color activeColor = AppTheme.primaryColor;
                    if (type == 'Expense') activeColor = AppTheme.errorColor;
                    if (type == 'Income') activeColor = AppTheme.primaryColor;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _typeFilter = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? activeColor : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selected ? activeColor : AppTheme.borderColor),
                          ),
                          child: Text(
                            type,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? Colors.black : AppTheme.textPrimary,
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
              // ── Period Filter (Daily, Monthly, Yearly) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.primaryColor : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? AppTheme.primaryColor : AppTheme.borderColor),
                          ),
                          child: Text(
                            labels[mode]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? Colors.black : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                child: _PeriodReport(provider: provider, mode: _mode, typeFilter: _typeFilter),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PeriodReport extends StatelessWidget {
  final ExpenseProvider provider;
  final _ReportMode mode;
  final String typeFilter;

  const _PeriodReport({required this.provider, required this.mode, required this.typeFilter});

  String _keyFor(DateTime date) {
    switch (mode) {
      case _ReportMode.daily: return DateFormat('MMM d, yyyy').format(date);
      case _ReportMode.monthly: return DateFormat('MMM yyyy').format(date);
      case _ReportMode.yearly: return DateFormat('yyyy').format(date);
    }
  }

  String _shortLabel(String key) => mode == _ReportMode.daily ? key.split(',').first : mode == _ReportMode.monthly ? key.split(' ').first : key;

  @override
  Widget build(BuildContext context) {
    final transactions = provider.expenses;
    final Map<String, Map<String, double>> dataPoints = {}; // key -> {income: val, expense: val}

    for (final t in transactions) {
      final key = _keyFor(t.date);
      dataPoints.putIfAbsent(key, () => {'income': 0, 'expense': 0});
      if (t.isIncome) {
        dataPoints[key]!['income'] = (dataPoints[key]!['income'] ?? 0) + t.amount;
      } else {
        dataPoints[key]!['expense'] = (dataPoints[key]!['expense'] ?? 0) + t.amount;
      }
    }

    final sortedKeys = dataPoints.keys.toList()
      ..sort((a, b) {
        try {
          DateTime da, db;
          switch (mode) {
            case _ReportMode.daily:
              da = DateFormat('MMM d, yyyy').parse(a);
              db = DateFormat('MMM d, yyyy').parse(b);
              break;
            case _ReportMode.monthly:
              da = DateFormat('MMM yyyy').parse(a);
              db = DateFormat('MMM yyyy').parse(b);
              break;
            case _ReportMode.yearly:
              da = DateTime(int.parse(a));
              db = DateTime(int.parse(b));
              break;
          }
          return db.compareTo(da); // newest first
        } catch (_) { return 0; }
      });

    if (sortedKeys.isEmpty) return const Center(child: Text('No data found', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)));

    final chartCount = mode == _ReportMode.daily ? 7 : mode == _ReportMode.monthly ? 6 : sortedKeys.length;
    final chartSlice = sortedKeys.length > chartCount ? sortedKeys.sublist(0, chartCount) : sortedKeys;
    final chartKeys = chartSlice.reversed.toList();

    double maxVal = 0;
    for (var key in chartKeys) {
      final dp = dataPoints[key]!;
      if (typeFilter == 'All') {
        maxVal = [maxVal, dp['income']!, dp['expense']!].reduce((a, b) => a > b ? a : b);
      } else if (typeFilter == 'Income') {
        maxVal = maxVal > dp['income']! ? maxVal : dp['income']!;
      } else {
        maxVal = maxVal > dp['expense']! ? maxVal : dp['expense']!;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overview', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
              if (typeFilter == 'All')
                Row(
                  children: [
                    _legendItem('Income', AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    _legendItem('Expense', AppTheme.errorColor),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= chartKeys.length) return const SizedBox.shrink();
                          return Padding(padding: const EdgeInsets.only(top: 4), child: Text(_shortLabel(chartKeys[idx]), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 55, getTitlesWidget: (val, meta) => Text('Rs ${val.toInt()}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9), maxLines: 1, softWrap: false))),
                  ),
                  barGroups: List.generate(chartKeys.length, (i) {
                    final key = chartKeys[i];
                    final dp = dataPoints[key]!;
                    final rods = <BarChartRodData>[];

                    if (typeFilter == 'All' || typeFilter == 'Income') {
                      rods.add(BarChartRodData(toY: dp['income']!, color: AppTheme.primaryColor, width: typeFilter == 'All' ? 8 : 16, borderRadius: BorderRadius.circular(4)));
                    }
                    if (typeFilter == 'All' || typeFilter == 'Expense') {
                      rods.add(BarChartRodData(toY: dp['expense']!, color: AppTheme.errorColor, width: typeFilter == 'All' ? 8 : 16, borderRadius: BorderRadius.circular(4)));
                    }

                    return BarChartGroupData(x: i, barRods: rods, barsSpace: 4);
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Breakdown', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...sortedKeys.map((key) {
            final dp = dataPoints[key]!;
            final showInc = typeFilter == 'All' || typeFilter == 'Income';
            final showExp = typeFilter == 'All' || typeFilter == 'Expense';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(key, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (showInc && dp['income']! > 0)
                    _breakdownRow('Income', dp['income']!, AppTheme.primaryColor),
                  if (showInc && showExp && dp['income']! > 0 && dp['expense']! > 0)
                    const SizedBox(height: 8),
                  if (showExp && dp['expense']! > 0)
                    _breakdownRow('Expense', dp['expense']!, AppTheme.errorColor),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _breakdownRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
        Text('Rs ${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
