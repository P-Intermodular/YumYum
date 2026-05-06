import 'package:flutter/material.dart';

import '../../../core/theme/yum_colors.dart';

/// Insignia inline que muestra la puntuación media y cantidad de valoraciones.
class InsigniaValoracionCompacta extends StatelessWidget {
  final double valoracion;
  final int cantidad;

  const InsigniaValoracionCompacta({
    super.key,
    required this.valoracion,
    required this.cantidad,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    if (cantidad == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline_rounded, color: colors.inkSoft, size: 16),
          const SizedBox(width: 4),
          Text(
            'Nuevo',
            style: TextStyle(
              fontSize: 13,
              color: colors.inkSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: colors.mustard, size: 16),
        const SizedBox(width: 4),
        Text(
          '${valoracion.toStringAsFixed(1)} ($cantidad)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
      ],
    );
  }
}
