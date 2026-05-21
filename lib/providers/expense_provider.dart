import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  double _monthlyTotal = 0;
  double get monthlyTotal => _monthlyTotal;

  Map<String, double> _categoryTotals = {};
  Map<String, double> get categoryTotals => _categoryTotals;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  ExpenseProvider() {
    loadExpenses();
  }

  // Load all expenses
  Future<void> loadExpenses() async {
    _expenses = await _dbHelper.getAllExpenses();
    await _updateMonthlyTotal();
    notifyListeners();
  }

  // Load monthly expenses
  Future<void> loadMonthlyExpenses() async {
    _expenses = await _dbHelper.getMonthlyExpenses();
    await _updateMonthlyTotal();
    notifyListeners();
  }

  // Add new expense
  Future<void> addExpense(Expense expense) async {
    final id = await _dbHelper.insertExpense(expense);
    final newExpense = Expense(
      id: id,
      title: expense.title,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
      notes: expense.notes,
      icon: expense.icon,
    );
    _expenses.insert(0, newExpense);
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _updateMonthlyTotal();
  }

  // Update expense
  Future<void> updateExpense(Expense expense) async {
    await _dbHelper.updateExpense(expense);
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      await _updateMonthlyTotal();
    } else {
      // If not in current list, reload to be safe
      await loadExpenses();
    }
  }

  // Delete expense
  Future<void> deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await _updateMonthlyTotal();
  }

  // Get expenses by category
  Future<List<Expense>> getExpensesByCategory(String category) async {
    return await _dbHelper.getExpensesByCategory(category);
  }

  // Update monthly total and category totals
  Future<void> _updateMonthlyTotal() async {
    _monthlyTotal = await _dbHelper.getMonthlyTotal();
    _categoryTotals = await _dbHelper.getTotalByCategory();
    notifyListeners();
  }

  // Get category totals
  Future<void> loadCategoryTotals() async {
    _categoryTotals = await _dbHelper.getTotalByCategory();
    notifyListeners();
  }

  // Search expenses
  Future<void> searchExpenses(String query) async {
    if (query.isEmpty) {
      await loadExpenses();
    } else {
      _expenses = await _dbHelper.searchExpenses(query);
      notifyListeners();
    }
  }

  // Get expenses by date range
  Future<void> getExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    _expenses = await _dbHelper.getExpensesByDateRange(startDate, endDate);
    await _updateMonthlyTotal();
    notifyListeners();
  }

  // Set selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}
