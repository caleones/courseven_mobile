import 'package:flutter/material.dart';

class AppTheme {
  
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color lightGold = Color(0xFFFFF8DC);
  static const Color premiumBlack = Color(0xFF0D0D0D);
  static const Color premiumWhite = Color(0xFFFAFAFA);
  static const Color softGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF242424);
  static const Color mediumGrey = Color(0xFF757575);
  
  static const Color successGreen = Color(0xFF2E7D32); 
  
  static const Color dangerRed = Color(0xFFD32F2F); 

  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: premiumWhite.withOpacity(0.9),
        selectedItemColor: goldAccent,
        unselectedItemColor: premiumBlack.withOpacity(0.6),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: goldAccent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: goldAccent, width: 2),
          foregroundColor: goldAccent,
          backgroundColor: premiumWhite,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: goldAccent,
        onPrimary: premiumBlack,
        secondary: darkGold,
        onSecondary: premiumWhite,
        surface: premiumWhite,
        onSurface: premiumBlack,
        background: softGrey,
        onBackground: premiumBlack,
        error: const Color(0xFFB00020),
      ),
      appBarTheme: AppBarTheme(
        elevation: 1,
        centerTitle: true,
        backgroundColor: premiumWhite.withOpacity(0.9),
        foregroundColor: premiumBlack,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: premiumBlack,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldAccent,
          foregroundColor: premiumBlack,
          elevation: 2,
          shadowColor: goldAccent.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: premiumWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mediumGrey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mediumGrey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: goldAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB00020)),
        ),
        labelStyle: TextStyle(color: mediumGrey),
        hintStyle: TextStyle(color: mediumGrey.withOpacity(0.7)),
      ),
      cardTheme: CardThemeData(
        elevation: 6,
        shadowColor: premiumBlack.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: premiumWhite,
      ),
    );
  }

  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: goldAccent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: goldAccent, width: 2),
          foregroundColor: goldAccent,
          backgroundColor: Colors.transparent,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      colorScheme: ColorScheme.dark(
        primary: goldAccent,
        onPrimary: premiumBlack,
        secondary: lightGold,
        onSecondary: premiumBlack,
        surface: darkGrey,
        onSurface: premiumWhite,
        background: premiumBlack,
        onBackground: premiumWhite,
        error: const Color(0xFFCF6679),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: premiumBlack,
        foregroundColor: premiumWhite,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: premiumWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldAccent,
          foregroundColor: premiumBlack,
          elevation: 2,
          shadowColor: goldAccent.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: premiumWhite.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: premiumWhite.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: goldAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCF6679)),
        ),
        labelStyle: TextStyle(color: premiumWhite.withOpacity(0.85)),
        hintStyle: TextStyle(color: premiumWhite.withOpacity(0.65)),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: goldAccent.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: darkGrey,
      ),
    );
  }
}
