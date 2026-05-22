import 'package:flutter/material.dart';

class IconHelper {
  static const Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Entertainment': Icons.movie_creation_rounded,
    'Utilities': Icons.lightbulb_outline_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Health': Icons.medical_services_rounded,
    'Education': Icons.school_rounded,
    'Salary': Icons.payments_rounded,
    'Business': Icons.business_center_rounded,
    'Investment': Icons.trending_up_rounded,
    'Other': Icons.category_rounded,
    'Grocery': Icons.local_grocery_store_rounded,
    'Rent': Icons.home_work_rounded,
    'Gift': Icons.card_giftcard_rounded,
    'Travel': Icons.flight_takeoff_rounded,
  };

  static IconData getIcon(String? iconKey) {
    if (iconKey == null) return Icons.category_rounded;
    
    // Simple check if it's an emoji (runes length)
    if (iconKey.runes.length <= 2) {
      return Icons.category_rounded;
    }
    
    return categoryIcons[iconKey] ?? Icons.category_rounded;
  }
}
