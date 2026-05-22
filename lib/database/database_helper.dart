import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/category.dart';

class DatabaseHelper {
  static const _databaseName = 'expense_tracker.db';
  static const _databaseVersion = 3;

  // expenses table
  static const table = 'expenses';
  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnAmount = 'amount';
  static const columnCategory = 'category';
  static const columnDate = 'date';
  static const columnNotes = 'notes';
  static const columnIcon = 'icon';
  static const columnIsIncome = 'is_income';

  // categories table
  static const catTable = 'categories';
  static const catColumnId = 'id';
  static const catColumnName = 'name';
  static const catColumnIcon = 'icon';
  static const catColumnColor = 'color';

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
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
        $columnIcon TEXT,
        $columnIsIncome INTEGER DEFAULT 0
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
    if (oldVersion < 3) {
      // Safely add is_income if it doesn't exist
      var columns = await db.rawQuery('PRAGMA table_info($table)');
      bool hasIncomeColumn = columns.any((c) => c['name'] == columnIsIncome);
      if (!hasIncomeColumn) {
        await db.execute('ALTER TABLE $table ADD COLUMN $columnIsIncome INTEGER DEFAULT 0');
      }
    }
  }

  // Helper to filter map keys to only those that exist in the table schema
  Future<Map<String, dynamic>> _filterSchema(String tableName, Map<String, dynamic> data) async {
    final db = await database;
    var columnsInfo = await db.rawQuery('PRAGMA table_info($tableName)');
    var validColumns = columnsInfo.map((c) => c['name'] as String).toSet();
    
    Map<String, dynamic> filtered = {};
    data.forEach((key, value) {
      if (validColumns.contains(key)) {
        filtered[key] = value;
      }
    });
    return filtered;
  }

  // ─── Category CRUD ──────────────────────────────────────────────────────────

  Future<List<ExpenseCategory>> getAllCategories() async {
    final db = await database;
    final maps = await db.query(catTable, orderBy: '$catColumnName ASC');
    return maps.map((m) => ExpenseCategory(
      name: m[catColumnName] as String,
      icon: m[catColumnIcon] as String,
      color: m[catColumnColor] as int,
    )).toList();
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

  Future<void> updateExpenseIconsForCategory(String categoryName, String newIcon) async {
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
    await db.delete(catTable, where: '$catColumnName = ?', whereArgs: [name]);
  }

  // Insert an expense
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    // Safe insert: filter out any keys that might not exist in the schema
    var data = await _filterSchema(table, expense.toMap());
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query(table, orderBy: '$columnDate DESC');
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final maps = await db.query(
      table,
      where: '$columnDate >= ? AND $columnDate <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: '$columnDate DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<List<Expense>> getExpensesByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      table,
      where: '$columnCategory = ?',
      whereArgs: [category],
      orderBy: '$columnDate DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<List<Expense>> getMonthlyExpenses() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);
    return getExpensesByDateRange(startDate, endDate);
  }

  Future<double> getMonthlyTotal() async {
    final expenses = await getMonthlyExpenses();
    return expenses.where((e) => !e.isIncome).fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<double> getMonthlyIncomeTotal() async {
    final transactions = await getMonthlyExpenses();
    return transactions.where((e) => e.isIncome).fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<Map<String, double>> getTotalByCategory() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT $columnCategory, SUM($columnAmount) as total FROM $table WHERE $columnIsIncome = 0 AND $columnDate >= ? AND $columnDate <= ? GROUP BY $columnCategory',
      [
        DateTime(DateTime.now().year, DateTime.now().month, 1).toIso8601String(),
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0).toIso8601String(),
      ],
    );

    Map<String, double> categoryTotals = {};
    for (var row in result) {
      categoryTotals[row[columnCategory] as String] = (row['total'] as num).toDouble();
    }
    return categoryTotals;
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    var data = await _filterSchema(table, expense.toMap());
    return await db.update(
      table,
      data,
      where: '$columnId = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<Expense?> getExpenseById(int id) async {
    final db = await database;
    final maps = await db.query(table, where: '$columnId = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Expense.fromMap(maps.first);
    return null;
  }

  Future<List<Expense>> searchExpenses(String query) async {
    final db = await database;
    final maps = await db.query(
      table,
      where: '$columnTitle LIKE ? OR $columnNotes LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: '$columnDate DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(table);
      await txn.delete(catTable);
    });
  }

  Future<Map<String, dynamic>> backupData() async {
    final db = await database;
    final expenses = await db.query(table);
    final categories = await db.query(catTable);
    return {
      'expenses': expenses,
      'categories': categories,
      'version': _databaseVersion,
    };
  }

  Future<void> restoreData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(table);
      await txn.delete(catTable);

      if (data['categories'] != null) {
        for (var cat in data['categories']) {
          await txn.insert(catTable, Map<String, dynamic>.from(cat));
        }
      }

      if (data['expenses'] != null) {
        for (var exp in data['expenses']) {
          var map = Map<String, dynamic>.from(exp);
          
          if (!map.containsKey(columnIsIncome)) {
            map[columnIsIncome] = 0;
          }

          var columnsInfo = await txn.rawQuery('PRAGMA table_info($table)');
          var validColumns = columnsInfo.map((c) => c['name'] as String).toSet();
          
          Map<String, dynamic> filteredMap = {};
          map.forEach((key, value) {
            if (validColumns.contains(key)) {
              filteredMap[key] = value;
            }
          });

          await txn.insert(table, filteredMap);
        }
      }
    });
  }
}
