import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'yum_colors.dart';

/// Define el tema visual compartido por toda la aplicación.
class AppTheme {
  /// Construye un tema claro a partir de la paleta semántica recibida.
  ///
  /// La tipografía (Inter sans + Fraunces display) y los radii son
  /// invariantes entre temas; solo cambian los colores.
  static ThemeData lightTheme(YumColors colors) {
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
      extensions: [colors],
      
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
        // El default de Flutter pinta el hint con bodyText.color al 60 %.
        // Como nuestra `inkSoft` es bastante saturada, el placeholder se
        // confundía con texto real. Lo bajamos al 45 % y peso normal para
        // que se lea como "sugerencia", no como contenido escrito.
        hintStyle: TextStyle(
          color: colors.inkSoft.withValues(alpha: 0.45),
          fontWeight: FontWeight.w400,
        ),
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
