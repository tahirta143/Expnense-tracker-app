import 'package:intl/intl.dart';

class Expense {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final String? icon;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.icon,
  });

  // Convert Expense to JSON for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
      'icon': icon ?? getCategoryIcon(category),
    };
  }

  // Create Expense from database map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      icon: map['icon'] as String?,
    );
  }

  // Get category icon
  static String getCategoryIcon(String category) {
    const icons = {
      'Food': '🍔',
      'Transport': '🚗',
      'Entertainment': '🎬',
      'Utilities': '💡',
      'Shopping': '🛍️',
      'Health': '🏥',
      'Education': '📚',
      'Other': '📌',
    };
    return icons[category] ?? '📌';
  }

  // Format currency
  String get formattedAmount {
    return 'Rs ${amount.toStringAsFixed(2)}';
  }

  // Format date
  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String get formattedDateTime {
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  @override
  String toString() {
    return 'Expense(id: $id, title: $title, amount: $amount, category: $category, date: $date)';
  }
}
