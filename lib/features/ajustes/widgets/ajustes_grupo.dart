import 'package:flutter/material.dart';

import '../../../core/theme/yum_colors.dart';

/// Sección agrupada de items de ajustes con título en mayúsculas.
///
/// Equivalente al `<Group>` del prototipo-figma: un encabezado fino y una
/// tarjeta unificada que contiene los [AjustesTile] dados.
class AjustesGrupo extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const AjustesGrupo({
    super.key,
    required this.titulo,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            titulo.toUpperCase(),
            style: TextStyle(
              color: colors.inkSoft,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.paper,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}
