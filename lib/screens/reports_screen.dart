import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../themes/app_theme.dart';
import '../models/expense.dart';

enum _ReportMode { daily, monthly, yearly }
enum _ViewType { timeline, categories }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportMode _mode = _ReportMode.daily;
  String _typeFilter = 'All'; // 'All', 'Expense', 'Income'
  _ViewType _viewType = _ViewType.timeline;
  String _categoryFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<ExpenseProvider, CategoryProvider>(
      builder: (context, provider, categoryProvider, _) {
        final categories = ['All', ...categoryProvider.categories.map((c) => c.name)];
        
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) => Opacity(opacity: value, child: child!),
          child: Column(
            children: [
              // ── View Type Toggle (Timeline vs Categories) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _toggleButton(
                        label: 'Timeline', 
                        isSelected: _viewType == _ViewType.timeline,
                        onTap: () => setState(() => _viewType = _ViewType.timeline),
                        icon: Icons.show_chart_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _toggleButton(
                        label: 'Categories', 
                        isSelected: _viewType == _ViewType.categories,
                        onTap: () => setState(() => _viewType = _ViewType.categories),
                        icon: Icons.pie_chart_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Filters Row (Type & Category) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Type Filter Dropdown
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: !isDark ? [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                          ] : [],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _typeFilter,
                            isExpanded: true,
                            dropdownColor: theme.cardColor,
                            items: ['All', 'Expense', 'Income'].map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: theme.textTheme.titleMedium?.color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _typeFilter = val!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category Filter Dropdown
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: !isDark ? [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                          ] : [],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _categoryFilter,
                            isExpanded: true,
                            dropdownColor: theme.cardColor,
                            items: categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(
                                  cat,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textTheme.titleMedium?.color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _categoryFilter = val!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // ── Period Filter (Daily, Monthly, Yearly) ──
              if (_viewType == _ViewType.timeline)
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
                              color: selected ? AppTheme.primaryColor : theme.cardColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !selected && !isDark ? [
                                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                              ] : [],
                            ),
                            child: Text(
                              labels[mode]!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected ? Colors.black : theme.textTheme.titleSmall?.color,
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
                child: _viewType == _ViewType.timeline
                    ? _PeriodReport(
                        provider: provider, 
                        mode: _mode, 
                        typeFilter: _typeFilter,
                        categoryFilter: _categoryFilter,
                      )
                    : _CategoryReport(
                        provider: provider, 
                        typeFilter: _typeFilter,
                        categoryFilter: _categoryFilter,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toggleButton({required String label, required bool isSelected, required VoidCallback onTap, required IconData icon}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.black : AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : theme.textTheme.titleMedium?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodReport extends StatelessWidget {
  final ExpenseProvider provider;
  final _ReportMode mode;
  final String typeFilter;
  final String categoryFilter;

  const _PeriodReport({
    required this.provider, 
    required this.mode, 
    required this.typeFilter,
    required this.categoryFilter,
  });

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    var transactions = provider.expenses;

    // Apply Filters
    if (typeFilter == 'Expense') {
      transactions = transactions.where((e) => !e.isIncome).toList();
    } else if (typeFilter == 'Income') {
      transactions = transactions.where((e) => e.isIncome).toList();
    }

    if (categoryFilter != 'All') {
      transactions = transactions.where((e) => e.category == categoryFilter).toList();
    }

    final Map<String, Map<String, double>> dataPoints = {}; // key -> {income: val, expense: val}

    for (final t in transactions) {
      if (t.category == 'Transfer' && categoryFilter != 'Transfer') continue;
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

    if (sortedKeys.isEmpty) return Center(child: Text('No data found', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14)));

    final chartCount = mode == _ReportMode.daily ? 7 : mode == _ReportMode.monthly ? 6 : sortedKeys.length;
    final chartSlice = sortedKeys.length > chartCount ? sortedKeys.sublist(0, chartCount) : sortedKeys;
    final chartKeys = chartSlice.reversed.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overview', style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 15, fontWeight: FontWeight.bold)),
              if (typeFilter == 'All')
                Row(
                  children: [
                    _legendItem(context, 'Income', AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    _legendItem(context, 'Expense', AppTheme.errorColor),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: theme.cardColor, 
              borderRadius: BorderRadius.circular(16), 
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true, 
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= chartKeys.length) return const SizedBox.shrink();
                          return Padding(padding: const EdgeInsets.only(top: 4), child: Text(_shortLabel(chartKeys[idx]), style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 9)));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 55, getTitlesWidget: (val, meta) => Text('Rs ${val.toInt()}', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 9), maxLines: 1, softWrap: false))),
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
          Text('Breakdown', style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...sortedKeys.map((key) {
            final dp = dataPoints[key]!;
            final showInc = typeFilter == 'All' || typeFilter == 'Income';
            final showExp = typeFilter == 'All' || typeFilter == 'Expense';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor, 
                borderRadius: BorderRadius.circular(16), 
                boxShadow: isDark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(key, style: TextStyle(color: theme.textTheme.titleMedium?.color, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (showInc && dp['income']! > 0)
                    _breakdownRow(context, 'Income', dp['income']!, AppTheme.primaryColor),
                  if (showInc && showExp && dp['income']! > 0 && dp['expense']! > 0)
                    const SizedBox(height: 8),
                  if (showExp && dp['expense']! > 0)
                    _breakdownRow(context, 'Expense', dp['expense']!, AppTheme.errorColor),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _legendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10)),
      ],
    );
  }

  Widget _breakdownRow(BuildContext context, String label, double amount, Color color) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
          ],
        ),
        Text('Rs ${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _CategoryReport extends StatelessWidget {
  final ExpenseProvider provider;
  final String typeFilter;
  final String categoryFilter;

  const _CategoryReport({
    required this.provider, 
    required this.typeFilter,
    required this.categoryFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Filter transactions based on type
    var transactions = provider.expenses;
    if (typeFilter == 'Expense') {
      transactions = transactions.where((e) => !e.isIncome && e.category != 'Transfer').toList();
    } else if (typeFilter == 'Income') {
      transactions = transactions.where((e) => e.isIncome && e.category != 'Transfer').toList();
    } else {
      transactions = transactions.where((e) => e.category != 'Transfer').toList();
    }

    if (categoryFilter != 'All') {
      transactions = transactions.where((e) => e.category == categoryFilter).toList();
    }

    // Aggregate by category
    final Map<String, double> categoryMap = {};
    double total = 0;

    for (var t in transactions) {
      categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
      total += t.amount;
    }

    // Sort categories by amount
    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return Center(child: Text('No data for categories', style: TextStyle(color: theme.textTheme.bodySmall?.color)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Distribution', style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Pie Chart
          Container(
            height: 240,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: sortedCategories.map((entry) {
                  final color = AppTheme.getCategoryColor(entry.key);
                  final percentage = (entry.value / total * 100).toStringAsFixed(1);
                  
                  return PieChartSectionData(
                    color: color,
                    value: entry.value,
                    title: '$percentage%',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Text('Category Ranking', style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          ...sortedCategories.map((entry) {
            final color = AppTheme.getCategoryColor(entry.key);
            final percentage = entry.value / total;
            final icon = provider.expenses.firstWhere(
              (e) => e.category == entry.key, 
              orElse: () => Expense(title: '', amount: 0, category: '', date: DateTime.now())
            ).icon ?? '📌';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key, style: TextStyle(color: theme.textTheme.titleMedium?.color, fontWeight: FontWeight.bold)),
                            Text('${(percentage * 100).toStringAsFixed(1)}% of total', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text('Rs ${entry.value.toStringAsFixed(0)}', style: TextStyle(color: theme.textTheme.titleMedium?.color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
