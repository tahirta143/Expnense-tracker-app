import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../themes/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/curved_bottom_nav.dart';
import '../widgets/expense_card.dart';
import '../utils/backup_helper.dart';
import 'expense_list_screen.dart';
import 'reports_screen.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _searchActive = false;
  final TextEditingController _searchController = TextEditingController();

  // Draggable FAB position (bottom-right default)
  double _fabX = -1;
  double _fabY = -1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ExpenseProvider>().loadMonthlyExpenses();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExpenseSheet(
        onSave: (expense) {
          context.read<ExpenseProvider>().addExpense(expense);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction added successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_fabX < 0) {
      final size = MediaQuery.of(context).size;
      _fabX = size.width - 72;
      _fabY = size.height - 160;
    }

    final titles = ['Dashboard', 'Transactions', 'Reports', 'Categories'];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _searchActive
          ? _buildSearchBar()
          : CustomAppBar(
              title: titles[_selectedIndex],
              showBackButton: false,
              actions: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _searchActive = true),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppTheme.primaryColor),
                      color: AppTheme.cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) async {
                        if (value == 'export') {
                          try {
                            await BackupHelper.exportBackup();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Backup exported successfully!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Export failed: $e')),
                              );
                            }
                          }
                        } else if (value == 'import') {
                          try {
                            bool success = await BackupHelper.importBackup();
                            if (success && context.mounted) {
                              context.read<ExpenseProvider>().loadExpenses();
                              context.read<CategoryProvider>().loadCategories();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Backup imported successfully!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Import failed: $e')),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.upload, color: AppTheme.primaryColor, size: 20),
                              SizedBox(width: 10),
                              Text('Export Backup', style: TextStyle(color: AppTheme.textPrimary)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'import',
                          child: Row(
                            children: [
                              Icon(Icons.download, color: AppTheme.primaryColor, size: 20),
                              SizedBox(width: 10),
                              Text('Import Backup', style: TextStyle(color: AppTheme.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
      body: Stack(
        children: [
          Consumer<ExpenseProvider>(
            builder: (context, expenseProvider, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: IndexedStack(
                  key: ValueKey<int>(_selectedIndex),
                  index: _selectedIndex,
                  children: [
                    _buildDashboard(context, expenseProvider),
                    const ExpenseListScreen(),
                    const ReportsScreen(),
                    const CategoryScreen(),
                  ],
                ),
              );
            },
          ),
          if (_searchActive) _buildSearchOverlay(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CurvedBottomNavigationBar(
              selectedIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  _searchActive = false;
                });
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.list_rounded), label: 'Expenses'),
                BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Reports'),
                BottomNavigationBarItem(icon: Icon(Icons.category_rounded), label: 'Category'),
              ],
            ),
          ),
          Positioned(
            left: _fabX - 28,
            top: _fabY - 28,
            child: GestureDetector(
              onPanUpdate: (details) {
                final size = MediaQuery.of(context).size;
                setState(() {
                  _fabX = (_fabX + details.delta.dx).clamp(28.0, size.width - 28.0);
                  _fabY = (_fabY + details.delta.dy).clamp(28.0, size.height - 100.0);
                });
              },
              child: FloatingActionButton(
                onPressed: _showAddExpenseSheet,
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                elevation: 6,
                child: const Icon(Icons.add, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSearchBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchActive = false;
                      _searchController.clear();
                      context.read<ExpenseProvider>().loadMonthlyExpenses();
                    });
                  },
                  child: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (q) {
                      context.read<ExpenseProvider>().searchExpenses(q);
                    },
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      context.read<ExpenseProvider>().loadMonthlyExpenses();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, int id) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Transaction', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this transaction?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ExpenseProvider>().deleteExpense(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted'), duration: Duration(seconds: 2)));
    }
  }

  Widget _buildSearchOverlay() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        if (_searchController.text.isEmpty) return const SizedBox.shrink();
        return Container(
          color: AppTheme.backgroundColor,
          child: provider.expenses.isEmpty
              ? Center(child: Text('No results for "${_searchController.text}"', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: provider.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = provider.expenses[index];
                    return ExpenseCard(expense: expense, index: index, onDelete: () => _confirmDelete(context, expense.id!));
                  },
                ),
        );
      },
    );
  }

  Widget _buildDashboard(BuildContext context, ExpenseProvider provider) {
    final now = DateTime.now();
    final sw = MediaQuery.of(context).size.width;
    final monthName = DateFormat('MMMM, yyyy').format(now);
    final recentExpenses = provider.expenses.take(5).toList();
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: sw * 0.03, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(monthName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.4,
              children: [
                _summaryCard(title: 'Total Income', value: 'Rs ${provider.monthlyIncomeTotal.toStringAsFixed(0)}', sub: 'this month', color: AppTheme.primaryColor, icon: '📈', delay: 0),
                _summaryCard(title: 'Total Expense', value: 'Rs ${provider.monthlyTotal.toStringAsFixed(0)}', sub: 'this month', color: AppTheme.errorColor, icon: '📉', delay: 100),
                _summaryCard(title: 'Balance', value: 'Rs ${(provider.monthlyIncomeTotal - provider.monthlyTotal).toStringAsFixed(0)}', sub: 'remaining', color: AppTheme.primaryColor, icon: '⚖️', delay: 200),
                _summaryCard(title: 'Transactions', value: provider.expenses.length.toString(), sub: 'this month', color: AppTheme.textPrimary, icon: '📝', delay: 300),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weekly Overview', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        _legendItem('Income', AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        _legendItem('Expense', Colors.red),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
                  decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
                  child: SizedBox(
                    height: 200,
                    child: BarChart(_getWeeklyBarChartData(provider, now)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Transactions', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                GestureDetector(onTap: () => setState(() => _selectedIndex = 1), child: const Text('View All', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          recentExpenses.isEmpty
              ? Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
                  child: const Center(child: Column(children: [Text('📭', style: TextStyle(fontSize: 40)), SizedBox(height: 10), Text('No transactions yet', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13))])),
                )
              : ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: recentExpenses.length, itemBuilder: (context, index) => ExpenseCard(expense: recentExpenses[index], index: index, onDelete: () => _confirmDelete(context, recentExpenses[index].id!))),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _summaryCard({required String title, required String value, required String sub, required Color color, required String icon, int delay = 0}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, anim, child) => Transform.scale(scale: anim, child: Opacity(opacity: anim.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderColor)),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _getWeeklyBarChartData(ExpenseProvider provider, DateTime now) {
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      double dailyIncome = 0;
      double dailyExpense = 0;

      for (var t in provider.expenses) {
        if (t.date.year == day.year && t.date.month == day.month && t.date.day == day.day) {
          if (t.isIncome) {
            dailyIncome += t.amount;
          } else {
            dailyExpense += t.amount;
          }
        }
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: dailyIncome,
              color: AppTheme.primaryColor,
              width: 8,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: dailyExpense,
              color: AppTheme.errorColor,
              width: 8,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return BarChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              if (value >= 0 && value < 7) {
                return Text(days[value.toInt()], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10));
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
              return Text('Rs ${value.toInt()}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8));
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  final void Function(Expense) onSave;
  const _AddExpenseSheet({required this.onSave});
  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = '';
  bool _isIncome = false;
  List<ExpenseCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _categories = context.read<CategoryProvider>().categories.toList();
    if (_categories.isNotEmpty) _selectedCategory = _categories.first.name;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.primaryColor, surface: AppTheme.cardColor)), child: child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppTheme.errorColor));
      return;
    }
    
    String icon = '📌';
    if (_isIncome) {
      if (_selectedCategory == 'Salary') {
        icon = '💵';
      } else if (_selectedCategory == 'Business') {
        icon = '📈';
      } else if (_selectedCategory == 'Investment') {
        icon = '🏦';
      } else {
        icon = '💰';
      }
    } else {
      icon = _categories.isNotEmpty ? _categories.firstWhere((c) => c.name == _selectedCategory, orElse: () => _categories.first).icon : '📌';
    }

    final expense = Expense(
      title: _titleController.text,
      amount: double.tryParse(_amountController.text) ?? 0,
      category: _isIncome ? _selectedCategory : _selectedCategory,
      date: _selectedDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      icon: icon,
      isIncome: _isIncome,
    );
    widget.onSave(expense);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isIncome ? 'Add Income' : 'Add Expense', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Divider(color: AppTheme.borderColor, height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isIncome = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(color: !_isIncome ? Colors.red.withValues(alpha: 0.2) : AppTheme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: !_isIncome ? Colors.red : AppTheme.borderColor)),
                              child: Center(child: Text('Expense', style: TextStyle(color: !_isIncome ? Colors.red : AppTheme.textSecondary, fontWeight: FontWeight.bold))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isIncome = true;
                              if (!['Salary', 'Business', 'Investment', 'Other'].contains(_selectedCategory)) {
                                _selectedCategory = 'Salary';
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(color: _isIncome ? AppTheme.primaryColor.withValues(alpha: 0.2) : AppTheme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _isIncome ? AppTheme.primaryColor : AppTheme.borderColor)),
                              child: Center(child: Text('Income', style: TextStyle(color: _isIncome ? AppTheme.primaryColor : AppTheme.textSecondary, fontWeight: FontWeight.bold))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _label('Title *'),
                    const SizedBox(height: 8),
                    _field(controller: _titleController, hint: 'e.g., Salary, Rent, Grocery', icon: Icons.label_outline),
                    const SizedBox(height: 16),
                    _label('Amount *'),
                    const SizedBox(height: 8),
                    _field(controller: _amountController, hint: '0.00', icon: Icons.attach_money, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                    const SizedBox(height: 16),
                    _label('Category'),
                    const SizedBox(height: 10),
                    _isIncome ? _buildIncomeCategoryDropdown() : _buildExpenseCategoryDropdown(),
                    const SizedBox(height: 16),
                    _label('Date'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: AppTheme.cardColor, border: Border.all(color: AppTheme.borderColor), borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 18), const SizedBox(width: 10), Text(DateFormat('MMM d, yyyy').format(_selectedDate), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)), const Spacer(), const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary)]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Notes (Optional)'),
                    const SizedBox(height: 8),
                    _field(controller: _notesController, hint: 'Add notes...', icon: Icons.notes, maxLines: 3),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(gradient: AppTheme.getPrimaryGradient(), borderRadius: BorderRadius.circular(12)),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _submit,
                            borderRadius: BorderRadius.circular(12),
                            child: Center(child: Text(_isIncome ? 'Add Income' : 'Add Expense', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCategoryDropdown() {
    final incomeCats = ['Salary', 'Business', 'Investment', 'Other'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: AppTheme.cardColor,
          items: incomeCats.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: AppTheme.textPrimary)))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildExpenseCategoryDropdown() {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        final cats = catProvider.categories;
        if (cats.isEmpty) return const Text('No categories', style: TextStyle(color: AppTheme.textSecondary));
        if (!cats.any((c) => c.name == _selectedCategory)) _selectedCategory = cats.first.name;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: AppTheme.cardColor,
              items: cats.map((c) => DropdownMenuItem(value: c.name, child: Row(children: [Text(c.icon), const SizedBox(width: 10), Text(c.name, style: const TextStyle(color: AppTheme.textPrimary))]))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600));
  Widget _field({required TextEditingController controller, required String hint, required IconData icon, TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(controller: controller, style: const TextStyle(color: AppTheme.textPrimary), keyboardType: keyboardType, maxLines: maxLines, decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppTheme.textSecondary), prefixIcon: Icon(icon, color: AppTheme.primaryColor)));
  }
}
