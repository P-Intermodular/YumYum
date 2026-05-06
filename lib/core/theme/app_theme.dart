import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'yum_colors.dart';

/// Define el tema visual compartido por toda la aplicación.
class AppTheme {
  /// Construye el tema claro "Mesa de Barrio".
  static ThemeData get lightTheme {
    const colors = YumColors.light;

    // Tipografías
    final baseTextTheme = GoogleFonts.interTextTheme();
    final displayFont = GoogleFonts.fraunces();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colors.cream,
      primaryColor: colors.terracotta,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.terracotta,
        primary: colors.terracotta,
        onPrimary: colors.paper,
        secondary: colors.cream2,
        onSecondary: colors.ink,
        surface: colors.paper,
        onSurface: colors.ink,
        error: colors.tomato,
      ),
      
      // Añadimos nuestra extensión de colores semánticos
      extensions: const [colors],
      
      textTheme: baseTextTheme.copyWith(
        displayLarge: displayFont.copyWith(color: colors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.01),
        displayMedium: displayFont.copyWith(color: colors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.01),
        displaySmall: displayFont.copyWith(color: colors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.01),
        headlineLarge: displayFont.copyWith(color: colors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.01),
        headlineMedium: displayFont.copyWith(color: colors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.01),
        headlineSmall: displayFont.copyWith(color: colors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.01),
        titleLarge: displayFont.copyWith(color: colors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.01),
      ).apply(
        bodyColor: colors.ink,
        displayColor: colors.ink,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: colors.cream.withValues(alpha: 0.85),
        foregroundColor: colors.ink,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      
      cardTheme: CardThemeData(
        color: colors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.line),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.terracotta, width: 2),
        ),
      ),
    );
  }
}
