import 'package:flutter/material.dart';

import '../../../core/theme/yum_colors.dart';

/// Encabezado simple y consistente para agrupar bloques del panel de pedidos.
class TituloSeccion extends StatelessWidget {
  final String titulo;

  const TituloSeccion(this.titulo, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        titulo,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
      ),
    );
  }
}
