import 'package:flutter/material.dart';

/// Avatar reutilizable que muestra una imagen real o, en su defecto, iniciales.
///
/// El color de fondo se calcula de forma determinista a partir del
/// identificador recibido para mantener una apariencia estable en toda la app.
class AvatarUsuario extends StatelessWidget {
  final String nombre;
  final String? urlImagen;
  final String identificadorColor;
  final double radius;
  final String? preset;

  const AvatarUsuario({
    super.key,
    required this.nombre,
    required this.identificadorColor,
    this.urlImagen,
    this.radius = 20,
    this.preset,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorDesdeIdentificador(identificadorColor);
    final iniciales = _inicialesDesdeNombre(nombre);
    final urlNormalizada = urlImagen?.trim() ?? '';
    final presetNormalizado = preset?.trim() ?? '';
    final presetIcon = _iconoDesdePreset(presetNormalizado);

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.18),
      foregroundImage:
          urlNormalizada.isEmpty ? null : NetworkImage(urlNormalizada),
      child: presetIcon != null && urlNormalizada.isEmpty
          ? Icon(
              presetIcon,
              color: color,
              size: radius * 1.15,
            )
          : Text(
              iniciales,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.72,
              ),
            ),
    );
  }

  IconData? _iconoDesdePreset(String preset) {
    return switch (preset) {
      'chef' => Icons.restaurant_rounded,
      'leaf' => Icons.eco_rounded,
      'heart' => Icons.favorite_rounded,
      'star' => Icons.star_rounded,
      'spark' => Icons.auto_awesome_rounded,
      _ => null,
    };
  }

  String _inicialesDesdeNombre(String nombre) {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();

    if (partes.isEmpty) return 'U';
    if (partes.length == 1) return partes.first[0].toUpperCase();

    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  Color _colorDesdeIdentificador(String identificador) {
    const paleta = <Color>[
      Color(0xFF2E7D32),
      Color(0xFF1565C0),
      Color(0xFF6A1B9A),
      Color(0xFFEF6C00),
      Color(0xFFC62828),
      Color(0xFF00838F),
      Color(0xFF5D4037),
      Color(0xFF283593),
    ];

    final hash = identificador.runes.fold<int>(0, (acc, rune) => acc + rune);
    return paleta[hash % paleta.length];
  }
}
