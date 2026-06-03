import 'package:flutter/material.dart';

class AppTheme {
  // Colors for Dark Theme (Existing)
  static const Color primaryColor = Color(0xFF00D084);
  static const Color primaryDark = Color(0xFF008F5A);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color cardColor = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color borderColor = Color(0xFF3A3A3A);
  static const Color errorColor = Color(0xFFFF6B6B);

  // Colors for Light Theme (New - based on image)
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF707070);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightShadow = Color(0x1A000000);

  // Category colors
  static Map<String, Color> categoryColors = {
    'Food': const Color(0xFFFF6B6B),
    'Transport': const Color(0xFF4ECDC4),
    'Entertainment': const Color(0xFFFFE66D),
    'Utilities': const Color(0xFFA8E6CF),
    'Shopping': const Color(0xFFFF8B94),
    'Health': const Color(0xFFC7CEEA),
    'Education': const Color(0xFFB5EAD7),
    'Salary': const Color(0xFF00D084),
    'Business': const Color(0xFF4ECDC4),
    'Investment': const Color(0xFFFFE66D),
    'Other': const Color(0xFFF7DC6F),
  };

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCard,
      dividerColor: lightBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        surface: lightSurface,
        error: errorColor,
        onPrimary: Colors.white,
        onSurface: lightTextPrimary,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: lightSurface,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: lightTextPrimary),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(color: lightTextPrimary)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: lightSurface,
        headerBackgroundColor: primaryColor,
        headerForegroundColor: Colors.white,
        dayStyle: const TextStyle(color: lightTextPrimary),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(color: lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: lightTextSecondary, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: lightTextPrimary, fontSize: 22, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: lightTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: lightTextPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: lightTextPrimary, fontSize: 14),
        bodySmall: TextStyle(color: lightTextSecondary, fontSize: 12),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 8,
        extendedTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      textTheme: const TextTheme(
        displayLarge:
            TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium:
            TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        headlineLarge:
            TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium:
            TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
        headlineSmall:
            TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        titleLarge:
            TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium:
            TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        titleSmall:
            TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
        labelLarge:
            TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: textSecondary, fontSize: 12),
        labelSmall: TextStyle(color: textSecondary, fontSize: 11),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: cardColor,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: textPrimary),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(color: textPrimary)),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: cardColor,
        headerBackgroundColor: primaryColor,
        headerForegroundColor: Colors.black,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: textSecondary, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
    );
  }

  // Get category color
  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? categoryColors['Other']!;
  }

  // Get gradient
  static LinearGradient getPrimaryGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF00D084),
        Color(0xFF008F5A),
      ],
    );
  }
}
