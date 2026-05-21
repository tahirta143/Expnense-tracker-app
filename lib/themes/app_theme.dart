import 'package:flutter/material.dart';

class AppTheme {
  // Colors from the design - Dark theme with green accents
  static const Color primaryColor = Color(0xFF00D084);
  static const Color primaryDark = Color(0xFF008F5A);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color cardColor = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color borderColor = Color(0xFF3A3A3A);
  static const Color errorColor = Color(0xFFFF6B6B);
  static const Color successColor = Color(0xFF00D084);
  static const Color warningColor = Color(0xFFFFB84D);

  // Category colors
  static Map<String, Color> categoryColors = {
    'Food': const Color(0xFFFF6B6B),
    'Transport': const Color(0xFF4ECDC4),
    'Entertainment': const Color(0xFFFFE66D),
    'Utilities': const Color(0xFFA8E6CF),
    'Shopping': const Color(0xFFFF8B94),
    'Health': const Color(0xFFC7CEEA),
    'Education': const Color(0xFFB5EAD7),
    'Other': const Color(0xFFF7DC6F),
  };

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      // Global default text color = white
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
      // All text defaults to white; only use textSecondary explicitly where grey is intentional
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
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
