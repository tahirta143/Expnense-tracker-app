class ExpenseCategory {
  final String name;
  final String icon;
  final int color;

  ExpenseCategory({
    required this.name,
    required this.icon,
    required this.color,
  });

  static List<ExpenseCategory> getDefaultCategories() {
    return [
      ExpenseCategory(name: 'Food', icon: '🍔', color: 0xFFFF6B6B),
      ExpenseCategory(name: 'Transport', icon: '🚗', color: 0xFF4ECDC4),
      ExpenseCategory(name: 'Entertainment', icon: '🎬', color: 0xFFFFE66D),
      ExpenseCategory(name: 'Utilities', icon: '💡', color: 0xFFA8E6CF),
      ExpenseCategory(name: 'Shopping', icon: '🛍️', color: 0xFFFF8B94),
      ExpenseCategory(name: 'Health', icon: '🏥', color: 0xFFC7CEEA),
      ExpenseCategory(name: 'Education', icon: '📚', color: 0xFFB5EAD7),
      ExpenseCategory(name: 'Other', icon: '📌', color: 0xFFF7DC6F),
    ];
  }

  static ExpenseCategory getCategoryByName(String name) {
    try {
      return getDefaultCategories()
          .firstWhere((category) => category.name == name);
    } catch (e) {
      return getDefaultCategories().last; // Return 'Other' as default
    }
  }
}
