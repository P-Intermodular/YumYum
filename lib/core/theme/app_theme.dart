import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'yum_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const colors = YumColors.light;

    final baseTextTheme = GoogleFonts.interTextTheme();
    final displayFont = GoogleFonts.fraunces();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colors.cream,
      primaryColor: colors.mint,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.mint,
        primary: colors.mint,
        onPrimary: colors.ink,
        secondary: colors.mustard,
        onSecondary: colors.ink,
        surface: colors.paper,
        onSurface: colors.ink,
        error: colors.tomato,
      ),
      
      extensions: const [colors],
      
      textTheme: baseTextTheme.copyWith(
        displayLarge: displayFont.copyWith(color: colors.ink, fontWeight: FontWeight.bold),
        titleLarge: displayFont.copyWith(color: colors.ink, fontWeight: FontWeight.w600),
      ).apply(
        bodyColor: colors.ink,
        displayColor: colors.ink,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: colors.cream.withAlpha(220),
        foregroundColor: colors.ink,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      
      cardTheme: CardThemeData(
        color: colors.paper,
        elevation: 2,
        shadowColor: colors.mint.withAlpha(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.line),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.mint, width: 2),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.mint,
          foregroundColor: colors.ink,
          // Corrección: El peso de la fuente va dentro de textStyle
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}