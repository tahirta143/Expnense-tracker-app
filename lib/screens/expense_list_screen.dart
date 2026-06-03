import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../models/expense.dart';
import '../themes/app_theme.dart';
import '../widgets/expense_card.dart';
import '../models/category.dart';
import 'package:intl/intl.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String _selectedFilter = 'All';
  String _typeFilter = 'All'; // Added type filter

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<ExpenseProvider>().loadExpenses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<ExpenseProvider, CategoryProvider>(
      builder: (context, expenseProvider, categoryProvider, _) {
        final List<ExpenseCategory> categories = categoryProvider.categories;
        final List<String> filterOptions = ['All', ...categories.map((c) => c.name)];
        final List<String> typeOptions = ['All', 'Expense', 'Income'];

        var filteredExpenses = expenseProvider.expenses;

        // Apply type filter
        if (_typeFilter == 'Expense') {
          filteredExpenses = filteredExpenses.where((e) => !e.isIncome).toList();
        } else if (_typeFilter == 'Income') {
          filteredExpenses = filteredExpenses.where((e) => e.isIncome).toList();
        }

        // Apply category filter
        if (_selectedFilter != 'All') {
          filteredExpenses = filteredExpenses.where((e) => e.category == _selectedFilter).toList();
        }

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) => Opacity(opacity: value, child: child!),
          child: Column(
            children: [
              // Type Filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: typeOptions.map((type) {
                    final isSelected = _typeFilter == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _typeFilter = type),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : theme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? AppTheme.primaryColor : theme.dividerColor),
                            boxShadow: !isSelected && !isDark ? [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                            ] : [],
                          ),
                          child: Text(type, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.black : theme.textTheme.titleMedium?.color, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Category Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: filterOptions.map<Widget>((filter) {
                    final isSelected = filter == _selectedFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppTheme.primaryColor : theme.dividerColor),
                            boxShadow: !isSelected && !isDark ? [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                            ] : [],
                          ),
                          child: Text(filter, style: TextStyle(color: isSelected ? Colors.black : theme.textTheme.bodySmall?.color, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Transactions List
              Expanded(
                child: filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📭', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Text('No transactions found', style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 110),
                        itemCount: filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = filteredExpenses[index];
                          return ExpenseCard(
                            expense: expense,
                            index: index,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _EditExpenseSheet(
                                  expense: expense,
                                  onSave: (updated) => expenseProvider.updateExpense(updated),
                                ),
                              );
                            },
                            onDelete: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: theme.cardColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text('Delete Transaction', style: TextStyle(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
                                  content: Text('Are you sure you want to delete this transaction?', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color))),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor))),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                expenseProvider.deleteExpense(expense.id!);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EditExpenseSheet extends StatefulWidget {
  final Expense expense;
  final void Function(Expense) onSave;
  const _EditExpenseSheet({required this.expense, required this.onSave});
  @override
  State<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<_EditExpenseSheet> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late bool _isIncome;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(text: widget.expense.amount.toString());
    _notesController = TextEditingController(text: widget.expense.notes ?? '');
    _selectedDate = widget.expense.date;
    _selectedCategory = widget.expense.category;
    _isIncome = widget.expense.isIncome;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppTheme.errorColor));
      return;
    }
    final categories = context.read<CategoryProvider>().categories;
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
      icon = categories.isNotEmpty ? categories.firstWhere((c) => c.name == _selectedCategory, orElse: () => categories.first).icon : '📌';
    }

    final updated = Expense(
      id: widget.expense.id,
      title: _titleController.text,
      amount: double.tryParse(_amountController.text) ?? 0,
      category: _selectedCategory,
      date: _selectedDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      icon: icon,
      isIncome: _isIncome,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                  Text('Edit Transaction', style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close, color: theme.textTheme.bodySmall?.color)),
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
                    _label(context, 'Title *'),
                    const SizedBox(height: 8),
                    _field(context, controller: _titleController, hint: 'Title', icon: Icons.label_outline),
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
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context, 
                          initialDate: _selectedDate, 
                          firstDate: DateTime(2020), 
                          lastDate: DateTime.now()
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
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
                          child: InkWell(onTap: _submit, borderRadius: BorderRadius.circular(12), child: const Center(child: Text('Update Transaction', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)))),
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

  Widget _label(BuildContext context, String text) => Text(text, style: TextStyle(color: Theme.of(context).textTheme.titleSmall?.color, fontSize: 13, fontWeight: FontWeight.w600));

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

  Widget _field(BuildContext context, {required TextEditingController controller, required String hint, required IconData icon, TextInputType? keyboardType, int maxLines = 1}) {
    final theme = Theme.of(context);
    return TextField(controller: controller, style: TextStyle(color: theme.textTheme.bodyMedium?.color), keyboardType: keyboardType, maxLines: maxLines, decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color), prefixIcon: Icon(icon, color: AppTheme.primaryColor)));
  }
}
