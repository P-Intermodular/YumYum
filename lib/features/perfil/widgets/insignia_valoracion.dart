import 'package:flutter/material.dart';

import '../../../core/theme/yum_colors.dart';

/// Insignia compacta que resume la puntuación media del perfil.
class InsigniaValoracion extends StatelessWidget {
  final double valoracion;
  final int cantidad;

  const InsigniaValoracion({
    super.key,
    required this.valoracion,
    required this.cantidad,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colors.mustard.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: colors.mustard, size: 18),
          const SizedBox(width: 6),
          Text(
            cantidad == 0
                ? 'Nuevo'
                : '${valoracion.toStringAsFixed(1)} ($cantidad)',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.ink,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
