import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Premium Royal Blue & Teal design palette
  static const Color primaryGreen = Color(0xFF2563EB); // Royal Blue Primary
  static const Color deepBlue = Color(0xFF111827); // Slate Charcoal/Text Primary
  static const Color accentOrange = Color(0xFFF59E0B); // Amber Gold

  // Dark Palette specific constants
  static const Color darkPrimary = Color(0xFF4F8CFF); // Electric Blue Primary
  static const Color darkSecondary = Color(0xFFCBD5E1); // Platinum Slate Text Secondary
  static const Color darkBackground = Color(0xFF0B1220); // Obsidian Navy Background
  static const Color darkSurface = Color(0xFF151C2C); // Deep Surface Slate

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        onPrimary: Colors.white,
        secondary: Color(0xFF14B8A6), // Teal Secondary
        onSecondary: Colors.white,
        tertiary: accentOrange,
        onTertiary: Colors.white,
        surface: Color(0xFFF8FAFC), // Surface Light Grey
        onSurface: deepBlue,
        error: Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: deepBlue, size: 22),
        titleTextStyle: TextStyle(
          color: deepBlue,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
        ),
        color: const Color(0xFFFFFFFF),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        labelStyle: const TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.w500, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepBlue,
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF8FAFC),
        disabledColor: Colors.transparent,
        selectedColor: primaryGreen.withOpacity(0.12),
        secondarySelectedColor: primaryGreen,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(color: deepBlue, fontWeight: FontWeight.w600, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: Colors.white,
        secondary: Color(0xFF14B8A6), // Teal Secondary
        onSecondary: Colors.white,
        tertiary: Color(0xFFFBBF24), // Amber Accent
        onTertiary: Colors.black,
        surface: darkSurface, // Deep Surface
        onSurface: Color(0xFFF8FAFC), // Text Primary
        error: Color(0xFFF87171),
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC), size: 22),
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1.0),
        ),
        color: darkSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        labelStyle: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        disabledColor: Colors.transparent,
        selectedColor: darkPrimary.withOpacity(0.15),
        secondarySelectedColor: darkPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: darkPrimary, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
      ),
    );
  }
}

