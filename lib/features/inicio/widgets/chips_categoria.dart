import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/categorias_producto.dart';
import '../../../core/theme/yum_colors.dart';
import '../providers/feed_filtros_providers.dart';

/// Chips horizontales de categorías con scroll. Replica figma.
///
/// El estado activo se persiste en `categoriaSeleccionadaProvider`.
/// El valor `null` representa "todas las categorías" (chip "Todo").
class ChipsCategoria extends ConsumerWidget {
  final FiltrosProductosScope scope;

  const ChipsCategoria({
    super.key,
    this.scope = FiltrosProductosScope.inicio,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seleccionada = scope == FiltrosProductosScope.inicio
        ? ref.watch(categoriaSeleccionadaProvider)
        : ref.watch(mapaCategoriaSeleccionadaProvider);
    final colors = context.yumColors;
    final items = <_ChipItem>[
      const _ChipItem(null, 'Todo', Icons.restaurant_outlined),
      for (final cat in CategoriaProducto.todas)
        _ChipItem(cat.valor, cat.label, cat.icono),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final activa = item.valor == seleccionada;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (scope == FiltrosProductosScope.inicio) {
                ref
                    .read(categoriaSeleccionadaProvider.notifier)
                    .set(item.valor);
              } else {
                ref
                    .read(mapaCategoriaSeleccionadaProvider.notifier)
                    .set(item.valor);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: activa ? colors.ink : colors.paper,
                border: Border.all(
                  color: activa ? colors.ink : colors.line,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icono,
                    size: 14,
                    color: activa ? colors.paper : colors.inkSoft,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: activa ? colors.paper : colors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChipItem {
  final String? valor;
  final String label;
  final IconData icono;

  const _ChipItem(this.valor, this.label, this.icono);
}
