import '../database/database_helper.dart';
import '../models/category.dart';
import '../themes/app_theme.dart';
import 'package:flutter/material.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<ExpenseCategory> _categories = [];

  List<ExpenseCategory> get categories => List.unmodifiable(_categories);

  CategoryProvider() {
    loadCategories();
  }

  Future<void> loadCategories() async {
    _categories = await _db.getAllCategories();
    // Sync colors to AppTheme for widgets to use
    for (var cat in _categories) {
      AppTheme.categoryColors[cat.name] = Color(cat.color);
    }
    notifyListeners();
  }

  Future<void> addCategory(ExpenseCategory category) async {
    await _db.insertCategory(category);
    await _db.updateExpenseIconsForCategory(category.name, category.icon);
    await loadCategories();
  }

  Future<void> deleteCategory(String name) async {
    await _db.deleteCategory(name);
    await loadCategories();
  }

  bool exists(String name) =>
      _categories.any((c) => c.name.toLowerCase() == name.toLowerCase());
}
