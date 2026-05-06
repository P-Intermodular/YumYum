import 'package:flutter/material.dart';

import '../../../core/theme/yum_colors.dart';

/// Encabezado de sección reutilizable: título + CTA opcional a la derecha.
///
/// Replica del `SectionTitle` de prototipo-figma (`screens-a.tsx`).
class SeccionTitulo extends StatelessWidget {
  final String titulo;
  final String? cta;
  final VoidCallback? onCtaTap;

  const SeccionTitulo({
    super.key,
    required this.titulo,
    this.cta,
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 18,
                    height: 1.2,
                    color: colors.ink,
                  ),
            ),
          ),
          if (cta != null)
            InkWell(
              onTap: onCtaTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  cta!,
                  style: TextStyle(
                    color: colors.terracottaDeep,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
