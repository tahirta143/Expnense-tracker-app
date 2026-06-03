import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../themes/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/curved_bottom_nav.dart';
import '../widgets/expense_card.dart';
import '../widgets/ai_insight_card.dart';
import '../utils/backup_helper.dart';
import '../services/ai_service.dart';
import 'expense_list_screen.dart';
import 'reports_screen.dart';
import 'category_screen.dart';
import 'wallet_screen.dart';
import '../providers/wallet_provider.dart';

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

  String _aiInsights = 'Tap refresh to generate AI insights based on your monthly transactions.';
  bool _aiLoading = false;
  bool _showAIInsights = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ExpenseProvider>().loadMonthlyExpenses();
      context.read<CategoryProvider>().loadCategories();
      
      // Fetch insights if data exists
      final expenseProvider = context.read<ExpenseProvider>();
      if (expenseProvider.expenses.isNotEmpty) {
        _fetchAIInsights();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchAIInsights() async {
    final provider = context.read<ExpenseProvider>();
    if (provider.expenses.isEmpty) {
      setState(() {
        _aiInsights = 'Add some transactions to get personalized financial advice.';
      });
      return;
    }

    setState(() => _aiLoading = true);
    try {
      final insights = await AIService().getFinancialInsights(provider.expenses);
      setState(() {
        _aiInsights = insights;
        _aiLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiInsights = 'Error connecting to AI advisor. Check your internet and API key.';
        _aiLoading = false;
      });
    }
  }

  void _showAIChatSheet(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => const _AIChatDialog(),
    );
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
    final theme = Theme.of(context);
    if (_fabX < 0) {
      final size = MediaQuery.of(context).size;
      _fabX = size.width - 72;
      _fabY = size.height - 160;
    }

    final titles = ['Dashboard', 'Wallets', 'Transactions', 'Reports', 'Categories'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _searchActive
          ? _buildSearchBar()
          : CustomAppBar(
              title: titles[_selectedIndex],
              showBackButton: false,
              actions: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showAIChatSheet(context),
                      icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryColor),
                      tooltip: 'Ask AI',
                    ),
                    IconButton(
                      onPressed: () => setState(() => _searchActive = true),
                      icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                      tooltip: 'Search',
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppTheme.primaryColor),
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
                        } else if (value == 'clear') {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Clear All Data'),
                              content: const Text('Are you sure you want to delete all transactions and categories? This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear', style: TextStyle(color: AppTheme.errorColor))),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            await DatabaseHelper().clearAllData();
                            if (context.mounted) {
                              context.read<ExpenseProvider>().loadExpenses();
                              context.read<CategoryProvider>().loadCategories();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared')));
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
                        const PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.delete_sweep_rounded, color: AppTheme.errorColor, size: 20),
                              SizedBox(width: 10),
                              Text('Clear All Data', style: TextStyle(color: AppTheme.errorColor)),
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
                    const WalletScreen(),
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
                BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallets'),
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
    final theme = Theme.of(context);
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          color: theme.appBarTheme.backgroundColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1),
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
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
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
                    icon: Icon(Icons.clear, color: theme.textTheme.bodySmall?.color, size: 20),
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
    final theme = Theme.of(ctx);
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Transaction', style: TextStyle(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this transaction?', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color))),
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
    final theme = Theme.of(context);
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        if (_searchController.text.isEmpty) return const SizedBox.shrink();
        return Container(
          color: theme.scaffoldBackgroundColor,
          child: provider.expenses.isEmpty
              ? Center(child: Text('No results for "${_searchController.text}"', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14)))
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final sw = MediaQuery.of(context).size.width;
    final monthName = DateFormat('MMMM, yyyy').format(now);
    final recentExpenses = provider.expenses.take(5).toList();
    final balance = provider.monthlyIncomeTotal - provider.monthlyTotal;
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: sw * 0.03, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              monthName, 
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color, 
                fontSize: 13, 
                fontWeight: FontWeight.w500
              )
            ),
          ),
          if (_showAIInsights) ...[
            const SizedBox(height: 12),
            AIInsightCard(
              insights: _aiInsights,
              isLoading: _aiLoading,
              onRefresh: _fetchAIInsights,
              onClose: () => setState(() => _showAIInsights = false),
            ),
          ],
          const SizedBox(height: 20),
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
                _summaryCard(context, title: 'Total Income', value: 'Rs ${provider.monthlyIncomeTotal.toStringAsFixed(0)}', sub: 'this month', color: AppTheme.primaryColor, icon: Icons.account_balance_wallet_rounded, delay: 0),
                _summaryCard(context, title: 'Total Expense', value: 'Rs ${provider.monthlyTotal.toStringAsFixed(0)}', sub: 'this month', color: AppTheme.errorColor, icon: Icons.shopping_cart_checkout_rounded, delay: 100),
                _summaryCard(context, title: 'Balance', value: 'Rs ${balance.toStringAsFixed(0)}', sub: 'remaining', color: balance < 0 ? AppTheme.errorColor : AppTheme.primaryColor, icon: Icons.account_balance_rounded, delay: 200),
                _summaryCard(context, title: 'Transactions', value: provider.expenses.length.toString(), sub: 'this month', color: theme.textTheme.titleLarge?.color ?? AppTheme.textPrimary, icon: Icons.receipt_long_rounded, delay: 300),
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
                    Text(
                      'Weekly Overview', 
                      style: TextStyle(
                        color: theme.textTheme.titleLarge?.color, 
                        fontSize: 15, 
                        fontWeight: FontWeight.bold
                      )
                    ),
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
                  decoration: BoxDecoration(
                    color: theme.cardColor, 
                    borderRadius: BorderRadius.circular(16), 
                    border: null,
                    boxShadow: isDark ? [] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: SizedBox(
                    height: 200,
                    child: BarChart(_getWeeklyBarChartData(provider, now, isDark)),
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
                Text(
                  'Recent Transactions', 
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color, 
                    fontSize: 15, 
                    fontWeight: FontWeight.bold
                  )
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 2), 
                  child: Text(
                    'View All', 
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color, 
                      fontSize: 12, 
                      fontWeight: FontWeight.w600
                    )
                  )
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          recentExpenses.isEmpty
              ? Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: theme.cardColor, 
                    borderRadius: BorderRadius.circular(16), 
                    border: null
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 40)), 
                        const SizedBox(height: 10), 
                        Text(
                          'No transactions yet', 
                          style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 13)
                        )
                      ]
                    )
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  itemCount: recentExpenses.length, 
                  itemBuilder: (context, index) => ExpenseCard(
                    expense: recentExpenses[index], 
                    index: index, 
                    onDelete: () => _confirmDelete(context, recentExpenses[index].id!)
                  )
                ),
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

  Widget _summaryCard(BuildContext context, {required String title, required String value, required String sub, required Color color, required IconData icon, int delay = 0}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, anim, child) => Transform.scale(scale: anim, child: Opacity(opacity: anim.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor, 
          borderRadius: BorderRadius.circular(14), 
          border: null,
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(title, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _getWeeklyBarChartData(ExpenseProvider provider, DateTime now, bool isDark) {
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
            getTitlesWidget: (value, meta) {
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              if (value >= 0 && value < 7) {
                return Text(
                  days[value.toInt()], 
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondary : Colors.grey, 
                    fontSize: 10
                  )
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
              return Text(
                'Rs ${value.toInt()}', 
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondary : Colors.grey, 
                  fontSize: 8
                )
              );
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
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppTheme.errorColor));
      return;
    }

    final wallets = context.read<WalletProvider>().wallets;
    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please create a wallet first'), backgroundColor: AppTheme.errorColor));
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
      walletId: wallets.first.id, // Default to first wallet for quick add
    );
    widget.onSave(expense);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isIncome ? 'Add Income' : 'Add Expense', style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close, color: theme.textTheme.bodySmall?.color)),
                ],
              ),
            ),
            Divider(color: theme.dividerColor, height: 1),
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
                              decoration: BoxDecoration(
                                color: !_isIncome ? Colors.red.withOpacity(0.2) : theme.cardColor, 
                                borderRadius: BorderRadius.circular(12), 
                                border: Border.all(color: !_isIncome ? Colors.red : theme.dividerColor)
                              ),
                              child: Center(child: Text('Expense', style: TextStyle(color: !_isIncome ? Colors.red : theme.textTheme.bodySmall?.color, fontWeight: FontWeight.bold))),
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
                              decoration: BoxDecoration(
                                color: _isIncome ? AppTheme.primaryColor.withOpacity(0.2) : theme.cardColor, 
                                borderRadius: BorderRadius.circular(12), 
                                border: Border.all(color: _isIncome ? AppTheme.primaryColor : theme.dividerColor)
                              ),
                              child: Center(child: Text('Income', style: TextStyle(color: _isIncome ? AppTheme.primaryColor : theme.textTheme.bodySmall?.color, fontWeight: FontWeight.bold))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _label(context, 'Title *'),
                    const SizedBox(height: 8),
                    _field(context, controller: _titleController, hint: 'e.g., Salary, Rent, Grocery', icon: Icons.label_outline),
                    const SizedBox(height: 16),
                    _label(context, 'Amount *'),
                    const SizedBox(height: 8),
                    _field(context, controller: _amountController, hint: '0.00', icon: Icons.attach_money, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                    const SizedBox(height: 16),
                    _label(context, 'Category'),
                    const SizedBox(height: 10),
                    _isIncome ? _buildIncomeCategoryDropdown(context) : _buildExpenseCategoryDropdown(context),
                    const SizedBox(height: 16),
                    _label(context, 'Date'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: theme.cardColor, border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 18), const SizedBox(width: 10), Text(DateFormat('MMM d, yyyy').format(_selectedDate), style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)), const Spacer(), Icon(Icons.arrow_drop_down, color: theme.textTheme.bodySmall?.color)]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label(context, 'Notes (Optional)'),
                    const SizedBox(height: 8),
                    _field(context, controller: _notesController, hint: 'Add notes...', icon: Icons.notes, maxLines: 3),
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

  Widget _buildIncomeCategoryDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final incomeCats = ['Salary', 'Business', 'Investment', 'Other'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: theme.cardColor,
          items: incomeCats.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: theme.textTheme.bodyMedium?.color)))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildExpenseCategoryDropdown(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        final cats = catProvider.categories;
        if (cats.isEmpty) return Text('No categories', style: TextStyle(color: theme.textTheme.bodySmall?.color));
        if (!cats.any((c) => c.name == _selectedCategory)) _selectedCategory = cats.first.name;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: theme.cardColor,
              items: cats.map((c) => DropdownMenuItem(value: c.name, child: Row(children: [Text(c.icon), const SizedBox(width: 10), Text(c.name, style: TextStyle(color: theme.textTheme.bodyMedium?.color))]))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
          ),
        );
      },
    );
  }

  Widget _label(BuildContext context, String text) => Text(text, style: TextStyle(color: Theme.of(context).textTheme.titleSmall?.color, fontSize: 13, fontWeight: FontWeight.w600));
  Widget _field(BuildContext context, {required TextEditingController controller, required String hint, required IconData icon, TextInputType? keyboardType, int maxLines = 1}) {
    final theme = Theme.of(context);
    return TextField(controller: controller, style: TextStyle(color: theme.textTheme.bodyMedium?.color), keyboardType: keyboardType, maxLines: maxLines, decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color), prefixIcon: Icon(icon, color: AppTheme.primaryColor)));
  }
}

class _AIChatDialog extends StatefulWidget {
  const _AIChatDialog();

  @override
  State<_AIChatDialog> createState() => _AIChatDialogState();
}

class _AIChatDialogState extends State<_AIChatDialog> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();

  void _askAI() async {
    final question = _queryController.text.trim();
    if (question.isEmpty) return;
    
    _queryController.clear();
    final provider = context.read<ExpenseProvider>();
    
    setState(() {
      _messages.add({'role': 'user', 'content': question});
      _isTyping = true;
    });
    
    _scrollToBottom();
    
    final allTransactions = await provider.getAllTransactions();
    final result = await AIService().askAI(allTransactions, question);
    
    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': result});
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sh = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: sh * 0.75, // Puts a limit on the dialog height
          color: theme.scaffoldBackgroundColor,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true, // Automatically handles keyboard
            body: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'AI Assistant',
                            style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              AIService().clearHistory();
                              setState(() => _messages.clear());
                            },
                            icon: Icon(Icons.refresh_rounded, color: theme.textTheme.bodySmall?.color, size: 20),
                            tooltip: 'Clear Chat',
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded, color: theme.textTheme.bodySmall?.color, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: theme.dividerColor, height: 1),
                
                // Chat Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.isEmpty ? 1 : _messages.length,
                    itemBuilder: (context, index) {
                      if (_messages.isEmpty) {
                        return Text(
                          'Ask me about your financial health, monthly summaries, or specific spending habits.\n\nExample:\n• Summarize my transactions for this month.\n• How is my daily spending trend?\n• Can I afford a Rs 10,000 expense next month?',
                          style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13, fontStyle: FontStyle.italic),
                        );
                      }
                      
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? AppTheme.primaryColor.withOpacity(0.2) : theme.cardColor,
                            borderRadius: BorderRadius.circular(12).copyWith(
                              bottomRight: isUser ? Radius.zero : null,
                              bottomLeft: isUser ? null : Radius.zero,
                            ),
                            border: Border.all(color: isUser ? AppTheme.primaryColor.withOpacity(0.3) : theme.dividerColor),
                          ),
                          child: Text(
                            msg['content']!,
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13, height: 1.4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                if (_isTyping)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),

                // Input Area
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: theme.appBarTheme.backgroundColor,
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _queryController,
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ask me anything...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: theme.cardColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onSubmitted: (_) => _askAI(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isTyping ? null : _askAI,
                        icon: Icon(Icons.send_rounded, color: _isTyping ? theme.textTheme.bodySmall?.color : AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
