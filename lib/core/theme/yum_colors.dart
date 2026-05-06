import 'package:flutter/material.dart';

/// Definicion de los colores corporativos de la aplicacion YumYum.
/// Implementa ThemeExtension para integrarse de forma nativa con el ThemeData.
class YumColors extends ThemeExtension<YumColors> {
  final Color cream;
  final Color cream2;
  final Color paper;
  final Color ink;
  final Color inkSoft;
  final Color mint;
  final Color mintDeep;
  final Color mustard;
  final Color olive;
  final Color oliveDeep;
  final Color tomato;
  final Color line;

  /// Alias de retrocompatibilidad.
  /// Mapea los nombres de colores antiguos a los nuevos de la paleta YumYum
  /// para evitar refactorizar las llamadas en todas las vistas de la aplicacion.
  Color get terracotta => mint;
  Color get terracottaDeep => mintDeep;

  const YumColors({
    required this.cream,
    required this.cream2,
    required this.paper,
    required this.ink,
    required this.inkSoft,
    required this.mint,
    required this.mintDeep,
    required this.mustard,
    required this.olive,
    required this.oliveDeep,
    required this.tomato,
    required this.line,
  });

  @override
  ThemeExtension<YumColors> copyWith({
    Color? cream,
    Color? cream2,
    Color? paper,
    Color? ink,
    Color? inkSoft,
    Color? mint,
    Color? mintDeep,
    Color? mustard,
    Color? olive,
    Color? oliveDeep,
    Color? tomato,
    Color? line,
  }) {
    return YumColors(
      cream: cream ?? this.cream,
      cream2: cream2 ?? this.cream2,
      paper: paper ?? this.paper,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      mint: mint ?? this.mint,
      mintDeep: mintDeep ?? this.mintDeep,
      mustard: mustard ?? this.mustard,
      olive: olive ?? this.olive,
      oliveDeep: oliveDeep ?? this.oliveDeep,
      tomato: tomato ?? this.tomato,
      line: line ?? this.line,
    );
  }

  @override
  ThemeExtension<YumColors> lerp(ThemeExtension<YumColors>? other, double t) {
    if (other is! YumColors) return this;
    
    return YumColors(
      cream: Color.lerp(cream, other.cream, t)!,
      cream2: Color.lerp(cream2, other.cream2, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      mintDeep: Color.lerp(mintDeep, other.mintDeep, t)!,
      mustard: Color.lerp(mustard, other.mustard, t)!,
      olive: Color.lerp(olive, other.olive, t)!,
      oliveDeep: Color.lerp(oliveDeep, other.oliveDeep, t)!,
      tomato: Color.lerp(tomato, other.tomato, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }

  /// Paleta de colores Light por defecto.
  static const light = YumColors(
    cream: Color(0xFFF2F9F6),
    cream2: Color(0xFFE0F0E9),
    paper: Color(0xFFFFFFFF),
    ink: Color(0xFF34495E),
    inkSoft: Color(0xFF5D6D7E),
    mint: Color(0xFF98D8B9),
    mintDeep: Color(0xFF76B897),
    mustard: Color(0xFFFFD56B),
    olive: Color(0xFF7FB394),
    oliveDeep: Color(0xFF4A705B),
    tomato: Color(0xFFF26D6D),
    line: Color(0xFFD1E8DD),
  );
}

/// Extension helper para acceder al tipado estricto del ThemeExtension.
extension YumColorsExtension on BuildContext {
  YumColors get yumColors => Theme.of(this).extension<YumColors>()!;
}