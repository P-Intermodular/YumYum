import 'package:flutter/material.dart';

class YumColors extends ThemeExtension<YumColors> {
  final Color cream;
  final Color cream2;
  final Color paper;
  final Color ink;
  final Color inkSoft;
  final Color terracotta;
  final Color terracottaDeep;
  final Color mustard;
  final Color olive;
  final Color oliveDeep;
  final Color tomato;
  final Color line;

  const YumColors({
    required this.cream,
    required this.cream2,
    required this.paper,
    required this.ink,
    required this.inkSoft,
    required this.terracotta,
    required this.terracottaDeep,
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
    Color? terracotta,
    Color? terracottaDeep,
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
      terracotta: terracotta ?? this.terracotta,
      terracottaDeep: terracottaDeep ?? this.terracottaDeep,
      mustard: mustard ?? this.mustard,
      olive: olive ?? this.olive,
      oliveDeep: oliveDeep ?? this.oliveDeep,
      tomato: tomato ?? this.tomato,
      line: line ?? this.line,
    );
  }

  @override
  ThemeExtension<YumColors> lerp(ThemeExtension<YumColors>? other, double t) {
    if (other is! YumColors) {
      return this;
    }
    return YumColors(
      cream: Color.lerp(cream, other.cream, t)!,
      cream2: Color.lerp(cream2, other.cream2, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      terracotta: Color.lerp(terracotta, other.terracotta, t)!,
      terracottaDeep: Color.lerp(terracottaDeep, other.terracottaDeep, t)!,
      mustard: Color.lerp(mustard, other.mustard, t)!,
      olive: Color.lerp(olive, other.olive, t)!,
      oliveDeep: Color.lerp(oliveDeep, other.oliveDeep, t)!,
      tomato: Color.lerp(tomato, other.tomato, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }

  static const light = YumColors(
    cream: Color(0xFFFBF6EC),
    cream2: Color(0xFFF3EADB),
    paper: Color(0xFFFFFDF8),
    ink: Color(0xFF2A1D15),
    inkSoft: Color(0xFF6B5B4E),
    terracotta: Color(0xFFC6553A),
    terracottaDeep: Color(0xFFA63E27),
    mustard: Color(0xFFE4A93A),
    olive: Color(0xFF5C6B3B),
    oliveDeep: Color(0xFF3E4A27),
    tomato: Color(0xFFD84A3A),
    line: Color(0xFFE8DCC7),
  );
}

// Helper extension para acceso fácil: context.yumColors.terracotta
extension YumColorsExtension on BuildContext {
  YumColors get yumColors => Theme.of(this).extension<YumColors>()!;
}
