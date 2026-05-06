import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/yum_colors.dart';

/// Orbe difuminado decorativo de fondo, en la línea estética del login.
///
/// Pensado para colocar dentro de un `Stack`. Se posiciona absolutamente y
/// pinta un círculo con `ImageFilter.blur` para crear el efecto glow cálido.
class OrbeGlow extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

  const OrbeGlow({
    super.key,
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Tono semántico del banner reutilizable de auth.
enum BannerAuthTono { exito, info, atencion }

/// Banner inline con tinte semántico de la marca para los flujos de
/// autenticación (recuperación, restablecimiento, registro).
class BannerAuth extends StatelessWidget {
  final BannerAuthTono tono;
  final IconData icono;
  final String texto;

  const BannerAuth({
    super.key,
    required this.tono,
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final (Color fondo, Color borde, Color textoColor) = switch (tono) {
      BannerAuthTono.exito => (
          colors.olive.withValues(alpha: 0.15),
          colors.olive.withValues(alpha: 0.35),
          colors.oliveDeep,
        ),
      BannerAuthTono.info => (
          colors.cream2,
          colors.line,
          colors.ink,
        ),
      BannerAuthTono.atencion => (
          colors.mustard.withValues(alpha: 0.20),
          colors.mustard.withValues(alpha: 0.45),
          colors.ink,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: textoColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: textoColor,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera reutilizable: logotipo + título grande + subtítulo.
class CabeceraAuth extends StatelessWidget {
  final String titulo;
  final String? subtitulo;

  const CabeceraAuth({
    super.key,
    required this.titulo,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.restaurant, color: colors.terracotta, size: 24),
            const SizedBox(width: 8),
            Text(
              'YumYum',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Text(
          titulo,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 30,
                height: 1.1,
              ),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitulo!,
            style: TextStyle(color: colors.inkSoft, fontSize: 14, height: 1.4),
          ),
        ],
      ],
    );
  }
}
