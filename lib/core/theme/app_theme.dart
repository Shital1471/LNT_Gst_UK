import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // New Design System Tokens (Dark Mode)
  static const Color voidDark = Color(0xFF0A0E16);
  static const Color panelDark = Color(0xFF11151F);
  static const Color panelRaisedDark = Color(0xFF151A26);
  static const Color hairlineDark = Color(0x12FFFFFF); // rgba(255,255,255,0.07)
  static const Color hairlineStrongDark = Color(0x1EFFFFFF); // rgba(255,255,255,0.12)
  static const Color saffronDark = Color(0xFFFF9D45);
  static const Color saffronDimDark = Color(0x24FF9D45); // rgba(255,157,69,0.14)
  static const Color jadeDark = Color(0xFF3ECF8E);
  static const Color jadeDimDark = Color(0x243ECF8E); // rgba(62,207,142,0.14)
  static const Color paperDark = Color(0xFFF4F5F8);
  static const Color mistDark = Color(0xFF8891A6);
  static const Color mistDimDark = Color(0xFF5B6376);

  // New Design System Tokens (Light Mode)
  static const Color voidLight = Color(0xFFF6F5F1);
  static const Color panelLight = Color(0xFFFFFFFF);
  static const Color panelRaisedLight = Color(0xFFFBFAF7);
  static const Color hairlineLight = Color(0x14141008); // rgba(20,16,8,0.08)
  static const Color hairlineStrongLight = Color(0x24141008); // rgba(20,16,8,0.14)
  static const Color saffronLight = Color(0xFFC25C12);
  static const Color saffronDimLight = Color(0x1AC25C12); // rgba(194,92,18,0.10)
  static const Color jadeLight = Color(0xFF0B7A49);
  static const Color jadeDimLight = Color(0x1A0B7A49); // rgba(11,122,73,0.10)
  static const Color paperLight = Color(0xFF1B1A17);
  static const Color mistLight = Color(0xFF6B6458);
  static const Color mistDimLight = Color(0xFF9A9286);
  static const Color onAccentLight = Color(0xFFFFF7EE);

  // Backwards Compatibility Mapping for existing direct references in other screens
  static const Color primaryGreen = saffronDark; 
  static const Color deepBlue = Color(0xFF1B1A17); // Maps to Light mode paper for contrast or readable text
  static const Color accentOrange = saffronDark; 
  static const Color darkPrimary = saffronDark; 
  static const Color darkSecondary = mistDark; 
  static const Color darkBackground = voidDark; 
  static const Color darkSurface = panelDark; 

  // Typography helper functions
  
  // Display font: Fraunces (serif) - For big stat numbers, titles, initials
  static TextStyle displayFont({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double letterSpacing = -0.01,
  }) {
    return GoogleFonts.fraunces(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // UI/Body font: Inter (sans-serif) - For nav labels, card titles, buttons, general UI
  static TextStyle uiFont({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // Data/Mono font: IBM Plex Mono (monospace) - For invoice IDs, currency values
  static TextStyle monoFont({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme _buildTextTheme(Color textColor, Color mutedColor, Color mutedDimColor) {
    return TextTheme(
      displayLarge: displayFont(fontSize: 32, fontWeight: FontWeight.w600, color: textColor),
      displayMedium: displayFont(fontSize: 28, fontWeight: FontWeight.w600, color: textColor),
      displaySmall: displayFont(fontSize: 22, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: displayFont(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: uiFont(fontSize: 14.5, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: uiFont(fontSize: 13.5, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: uiFont(fontSize: 15, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: uiFont(fontSize: 13.5, fontWeight: FontWeight.w400, color: textColor),
      bodySmall: uiFont(fontSize: 12, fontWeight: FontWeight.w400, color: mutedColor),
      labelLarge: uiFont(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
      labelMedium: uiFont(fontSize: 11, fontWeight: FontWeight.w500, color: mutedColor),
      labelSmall: uiFont(fontSize: 10, fontWeight: FontWeight.w400, color: mutedDimColor),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(paperLight, mistLight, mistDimLight);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: saffronLight,
        onPrimary: onAccentLight,
        secondary: jadeLight,
        onSecondary: Colors.white,
        surface: panelLight,
        onSurface: paperLight,
        error: Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: voidLight,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: voidLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: paperLight, size: 22),
        titleTextStyle: displayFont(
          color: paperLight,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: hairlineLight, width: 1.0),
        ),
        color: panelLight,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelLight,
        labelStyle: uiFont(color: mistLight, fontWeight: FontWeight.w500, fontSize: 13.5),
        hintStyle: uiFont(color: mistDimLight, fontSize: 13.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: hairlineLight, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: hairlineLight, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: saffronLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: saffronLight,
          foregroundColor: onAccentLight,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: uiFont(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: saffronLight,
          side: const BorderSide(color: hairlineStrongLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: uiFont(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panelLight,
        disabledColor: Colors.transparent,
        selectedColor: saffronDimLight,
        secondarySelectedColor: saffronLight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: uiFont(color: paperLight, fontWeight: FontWeight.w600, fontSize: 13),
        secondaryLabelStyle: uiFont(color: saffronLight, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: hairlineLight)),
      ),
      dividerTheme: const DividerThemeData(
        color: hairlineLight,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(paperDark, mistDark, mistDimDark);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: saffronDark,
        onPrimary: voidDark,
        secondary: jadeDark,
        onSecondary: voidDark,
        surface: panelDark,
        onSurface: paperDark,
        error: Color(0xFFF87171),
      ),
      scaffoldBackgroundColor: voidDark,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: voidDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: paperDark, size: 22),
        titleTextStyle: displayFont(
          color: paperDark,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: hairlineDark, width: 1.0),
        ),
        color: panelDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelDark,
        labelStyle: uiFont(color: mistDark, fontWeight: FontWeight.w500, fontSize: 13.5),
        hintStyle: uiFont(color: mistDimDark, fontSize: 13.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: hairlineDark, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: hairlineDark, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: saffronDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: saffronDark,
          foregroundColor: voidDark,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: uiFont(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: saffronDark,
          side: const BorderSide(color: hairlineStrongDark, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: uiFont(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panelDark,
        disabledColor: Colors.transparent,
        selectedColor: saffronDimDark,
        secondarySelectedColor: saffronDark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: uiFont(color: paperDark, fontWeight: FontWeight.w600, fontSize: 13),
        secondaryLabelStyle: uiFont(color: saffronDark, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: hairlineDark)),
      ),
      dividerTheme: const DividerThemeData(
        color: hairlineDark,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }
}
