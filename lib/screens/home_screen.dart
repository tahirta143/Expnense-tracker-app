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
import 'expense_list_screen.dart';
import 'reports_screen.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
      context.read<ExpenseProvider>().loadMonthlyExpenses();
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
              content: Text('Expense added successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set default FAB position once we have screen size
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

          // Search overlay
          if (_searchActive) _buildSearchOverlay(),

          // Floating bottom nav bar
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
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_rounded),
                  label: 'Expenses',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_rounded),
                  label: 'Reports',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.category_rounded),
                  label: 'Category',
                ),
              ],
            ),
          ),

          // Draggable FAB
          Positioned(
            left: _fabX - 28,
            top: _fabY - 28,
            child: GestureDetector(
              onPanUpdate: (details) {
                final size = MediaQuery.of(context).size;
                setState(() {
                  _fabX = (_fabX + details.delta.dx)
                      .clamp(28.0, size.width - 28.0);
                  _fabY = (_fabY + details.delta.dy)
                      .clamp(28.0, size.height - 100.0);
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

  // ─── Search App Bar ──────────────────────────────────────────────────────────

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
                  child: const Icon(Icons.arrow_back,
                      color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
                      hintStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (q) {
                      context.read<ExpenseProvider>().searchExpenses(q);
                    },
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear,
                        color: AppTheme.textSecondary, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      context
                          .read<ExpenseProvider>()
                          .loadMonthlyExpenses();
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

  // ─── Delete Confirmation ─────────────────────────────────────────────────────

  Future<void> _confirmDelete(BuildContext ctx, int id) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Expense',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this expense?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ExpenseProvider>().deleteExpense(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted'), duration: Duration(seconds: 2)),
      );
    }
  }

  // ─── Search Results Overlay ──────────────────────────────────────────────────

  Widget _buildSearchOverlay() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        if (_searchController.text.isEmpty) return const SizedBox.shrink();
        return Container(
          color: AppTheme.backgroundColor,
          child: provider.expenses.isEmpty
              ? Center(
                  child: Text(
                    'No results for "${_searchController.text}"',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: provider.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = provider.expenses[index];
                    return ExpenseCard(
                      expense: expense,
                      index: index,
                      onDelete: () => _confirmDelete(context, expense.id!),
                    );
                  },
                ),
        );
      },
    );
  }

  // ─── Dashboard ───────────────────────────────────────────────────────────────

  Widget _buildDashboard(BuildContext context, ExpenseProvider provider) {
    final now = DateTime.now();
    final sw = MediaQuery.of(context).size.width;
    final monthName = DateFormat('MMMM, yyyy').format(now);
    final recentExpenses = provider.expenses.take(5).toList();
    final todayTotal = provider.expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (sum, e) => sum + e.amount);

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: sw * 0.03, bottom: 100),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(opacity: value, child: child!);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              monthName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Summary Cards (2-column grid) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.6,
              children: [
                _summaryCard(
                  title: 'Total Expenses',
                  value: 'Rs ${provider.categoryTotals.values.fold(0.0, (a, b) => a + b).toStringAsFixed(0)}',
                  sub: 'all time',
                  color: AppTheme.errorColor,
                  icon: '💰',
                  delay: 0,
                ),
                _summaryCard(
                  title: 'This Month',
                  value: 'Rs ${provider.monthlyTotal.toStringAsFixed(0)}',
                  sub: '${provider.expenses.length} txns',
                  color: AppTheme.textPrimary,
                  icon: '💸',
                  delay: 100,
                ),
                _summaryCard(
                  title: 'Today',
                  value: 'Rs ${todayTotal.toStringAsFixed(0)}',
                  sub: 'spent today',
                  color: AppTheme.textPrimary,
                  icon: '📅',
                  delay: 200,
                ),

                _summaryCard(
                  title: 'Transactions',
                  value: provider.expenses.length.toString(),
                  sub: 'this month',
                  color: AppTheme.textPrimary,
                  icon: '📝',
                  delay: 300,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Weekly Bar Chart ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Week',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
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
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'Mon', 'Tue', 'Wed', 'Thu',
                                  'Fri', 'Sat', 'Sun'
                                ];
                                final idx = value.toInt();
                                if (idx < 0 || idx > 6) {
                                  return const SizedBox.shrink();
                                }
                                final isToday = idx == now.weekday - 1;
                                return Text(
                                  days[idx],
                                  style: TextStyle(
                                    color: isToday
                                        ? AppTheme.primaryColor
                                        : AppTheme.textSecondary,
                                    fontSize: 10,
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 55,
                              getTitlesWidget: (value, meta) => Text(
                                'Rs ${value.toInt()}',
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
                        barGroups: _getWeeklyBarGroups(provider, now),
                        gridData: const FlGridData(
                            show: true, drawVerticalLine: false),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Recent Transactions ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Text('📭', style: TextStyle(fontSize: 40)),
                        SizedBox(height: 10),
                        Text(
                          'No expenses yet',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = recentExpenses[index];
                    return ExpenseCard(
                      expense: expense,
                      index: index,
                      onDelete: () => _confirmDelete(context, expense.id!),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  // ─── Small Summary Card ──────────────────────────────────────────────────────

  Widget _summaryCard({
    required String title,
    required String value,
    required String sub,
    required Color color,
    required String icon,
    int delay = 0,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sw = MediaQuery.of(context).size.width;
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + delay),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, anim, child) {
            return Transform.scale(
              scale: anim,
              child: Opacity(opacity: anim.clamp(0.0, 1.0), child: child),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.03, vertical: sw * 0.025),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Text(icon, style: TextStyle(fontSize: sw * 0.055)),
                SizedBox(width: sw * 0.025),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: color,
                          fontSize: sw * 0.032,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: sw * 0.025,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  List<BarChartGroupData> _getWeeklyBarGroups(ExpenseProvider provider, DateTime now) {
    // weekday: 1=Mon … 7=Sun  →  index 0=Mon … 6=Sun
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final todayIndex = now.weekday - 1; // 0-based index of today

    // Always build 7 slots; future days stay 0
    final weeklyTotals = <int, double>{for (int i = 0; i < 7; i++) i: 0};

    for (var expense in provider.expenses) {
      final expenseDay = DateTime(
          expense.date.year, expense.date.month, expense.date.day);
      final diff = expenseDay.difference(startOfWeek).inDays;
      if (diff >= 0 && diff < 7) {
        weeklyTotals[diff] = (weeklyTotals[diff] ?? 0) + expense.amount;
      }
    }

    const colors = [
      Color(0xFF4ECDC4),
      Color(0xFF4ECDC4),
      Color(0xFF4ECDC4),
      Color(0xFF4ECDC4),
      Color(0xFF4ECDC4),
      Color(0xFF4ECDC4),
      Color(0xFF4ECDC4),
    ];

    return List.generate(
      7,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: weeklyTotals[i] ?? 0,
            // Today highlighted in primary green, past days teal, future days dim
            color: i == todayIndex
                ? AppTheme.primaryColor
                : i < todayIndex
                    ? colors[i]
                    : AppTheme.borderColor,
            width: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Expense Bottom Sheet ─────────────────────────────────────────────────

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
  List<ExpenseCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    // Categories load async — snapshot whatever is available now,
    // and if the list is empty we leave _selectedCategory blank
    // (the build method guards against this).
    _categories = context.read<CategoryProvider>().categories.toList();
    if (_categories.isNotEmpty) {
      _selectedCategory = _categories.first.name;
    }
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
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryColor,
            surface: AppTheme.cardColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a category first'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    final icon = _categories.isNotEmpty
        ? _categories
            .firstWhere((c) => c.name == _selectedCategory,
                orElse: () => _categories.first)
            .icon
        : '📌';
    final expense = Expense(
      title: _titleController.text,
      amount: double.tryParse(_amountController.text) ?? 0,
      category: _selectedCategory,
      date: _selectedDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      icon: icon,
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
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Expense',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.borderColor, height: 1),
            // Form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Expense Title *'),
                    const SizedBox(height: 8),
                    _field(
                        controller: _titleController,
                        hint: 'e.g., Coffee, Groceries',
                        icon: Icons.label_outline),
                    const SizedBox(height: 16),
                    _label('Amount *'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _amountController,
                      hint: '0.00',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                    const SizedBox(height: 16),
                    _label('Category'),
                    const SizedBox(height: 10),
                    // Use Consumer so the dropdown refreshes when categories load
                    Consumer<CategoryProvider>(
                      builder: (context, catProvider, _) {
                        final List<ExpenseCategory> cats = catProvider.categories.toList();
                        // Sync local state with latest list
                        if (cats.isNotEmpty &&
                            !cats.any((c) => c.name == _selectedCategory)) {
                          _selectedCategory = cats.first.name;
                          _categories = cats;
                        } else if (cats.isNotEmpty && _categories.isEmpty) {
                          _selectedCategory = cats.first.name;
                          _categories = cats;
                        }

                        if (cats.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppTheme.borderColor),
                            ),
                            child: const Text(
                              'No categories yet — add one in the Categories tab',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13),
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppTheme.borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory.isEmpty
                                  ? cats.first.name
                                  : _selectedCategory,
                              isExpanded: true,
                              dropdownColor: AppTheme.cardColor,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14),
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: AppTheme.textSecondary),
                              items: cats.map<DropdownMenuItem<String>>((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat.name,
                                  child: Row(
                                    children: [
                                      Text(cat.icon,
                                          style: const TextStyle(
                                              fontSize: 18)),
                                      const SizedBox(width: 10),
                                      Text(cat.name,
                                          style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 14)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedCategory = val;
                                    _categories = cats;
                                  });
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Date'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: AppTheme.primaryColor, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('MMM d, yyyy')
                                  .format(_selectedDate),
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down,
                                color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Notes (Optional)'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _notesController,
                      hint: 'Add any additional notes...',
                      icon: Icons.notes,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.getPrimaryGradient(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _submit,
                            borderRadius: BorderRadius.circular(12),
                            child: const Center(
                              child: Text(
                                'Add Expense',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppTheme.textPrimary),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      ),
    );
  }
}
