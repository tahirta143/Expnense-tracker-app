import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/category.dart';

class DatabaseHelper {
  static const _databaseName = 'expense_tracker.db';
  static const _databaseVersion = 2;

  // expenses table
  static const table = 'expenses';
  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnAmount = 'amount';
  static const columnCategory = 'category';
  static const columnDate = 'date';
  static const columnNotes = 'notes';
  static const columnIcon = 'icon';

  // categories table
  static const catTable = 'categories';
  static const catColumnId = 'id';
  static const catColumnName = 'name';
  static const catColumnIcon = 'icon';
  static const catColumnColor = 'color';

  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnAmount REAL NOT NULL,
        $columnCategory TEXT NOT NULL,
        $columnDate TEXT NOT NULL,
        $columnNotes TEXT,
        $columnIcon TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $catTable (
        $catColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $catColumnName TEXT NOT NULL UNIQUE,
        $catColumnIcon TEXT NOT NULL,
        $catColumnColor INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $catTable (
          $catColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $catColumnName TEXT NOT NULL UNIQUE,
          $catColumnIcon TEXT NOT NULL,
          $catColumnColor INTEGER NOT NULL
        )
      ''');
    }
  }

  // ─── Category CRUD ──────────────────────────────────────────────────────────

  Future<List<ExpenseCategory>> getAllCategories() async {
    final db = await database;
    final maps = await db.query(catTable, orderBy: '$catColumnName ASC');
    return maps
        .map((m) => ExpenseCategory(
              name: m[catColumnName] as String,
              icon: m[catColumnIcon] as String,
              color: m[catColumnColor] as int,
            ))
        .toList();
  }

  Future<void> insertCategory(ExpenseCategory cat) async {
    final db = await database;
    await db.insert(
      catTable,
      {
        catColumnName: cat.name,
        catColumnIcon: cat.icon,
        catColumnColor: cat.color,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateExpenseIconsForCategory(
      String categoryName, String newIcon) async {
    final db = await database;
    await db.update(
      table,
      {columnIcon: newIcon},
      where: '$columnCategory = ?',
      whereArgs: [categoryName],
    );
  }

  Future<void> deleteCategory(String name) async {
    final db = await database;
    await db.delete(catTable,
        where: '$catColumnName = ?', whereArgs: [name]);
  }

  // Insert an expense
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert(
      table,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query(table, orderBy: '$columnDate DESC');
    return List.generate(
      maps.length,
      (i) => Expense.fromMap(maps[i]),
    );
  }

  // Get expenses by date range
  Future<List<Expense>> getExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final maps = await db.query(
      table,
      where: '$columnDate >= ? AND $columnDate <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: '$columnDate DESC',
    );
    return List.generate(
      maps.length,
      (i) => Expense.fromMap(maps[i]),
    );
  }

  // Get expenses by category
  Future<List<Expense>> getExpensesByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      table,
      where: '$columnCategory = ?',
      whereArgs: [category],
      orderBy: '$columnDate DESC',
    );
    return List.generate(
      maps.length,
      (i) => Expense.fromMap(maps[i]),
    );
  }

  // Get expenses for current month
  Future<List<Expense>> getMonthlyExpenses() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);
    return getExpensesByDateRange(startDate, endDate);
  }

  // Get total expenses for the month
  Future<double> getMonthlyTotal() async {
    final expenses = await getMonthlyExpenses();
    double total = 0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  // Get total by category
  Future<Map<String, double>> getTotalByCategory() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT $columnCategory, SUM($columnAmount) as total FROM $table WHERE $columnDate >= ? AND $columnDate <= ? GROUP BY $columnCategory',
      [
        DateTime(DateTime.now().year, DateTime.now().month, 1).toIso8601String(),
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0).toIso8601String(),
      ],
    );

    Map<String, double> categoryTotals = {};
    for (var row in result) {
      categoryTotals[row['$columnCategory'] as String] =
          (row['total'] as num).toDouble();
    }
    return categoryTotals;
  }

  // Update an expense
  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      table,
      expense.toMap(),
      where: '$columnId = ?',
      whereArgs: [expense.id],
    );
  }

  // Delete an expense
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Get expense by ID
  Future<Expense?> getExpenseById(int id) async {
    final db = await database;
    final maps = await db.query(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  // Search expenses
  Future<List<Expense>> searchExpenses(String query) async {
    final db = await database;
    final maps = await db.query(
      table,
      where: '$columnTitle LIKE ? OR $columnNotes LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: '$columnDate DESC',
    );
    return List.generate(
      maps.length,
      (i) => Expense.fromMap(maps[i]),
    );
  }

  // Clear all expenses
  Future<int> deleteAllExpenses() async {
    final db = await database;
    return await db.delete(table);
  }
}
