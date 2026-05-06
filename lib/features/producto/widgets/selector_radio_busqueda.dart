import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/yum_colors.dart';
import '../providers/producto_providers.dart';

/// Selector del radio de busqueda por proximidad.
///
/// Acepta `null` como "Todas las distancias" (opcion por defecto, sin
/// limitacion geografica). Las demas opciones son los radios discretos
/// definidos en `radiosDisponiblesKm`.
class SelectorRadioBusqueda extends ConsumerWidget {
  const SelectorRadioBusqueda({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioActual = ref.watch(radioBusquedaProvider);
    final colors = context.yumColors;

    return GestureDetector(
      onTap: () => _mostrarOpciones(context, ref, radioActual, colors),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (radioActual == null)
              Text(
                'Cualquier distancia',
                style: TextStyle(
                  color: colors.ink,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              )
            else ...[
              Text(
                'Radio:',
                style: TextStyle(
                  color: colors.inkSoft,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${radioActual.toInt()} km',
                style: TextStyle(
                  color: colors.ink,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: colors.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }

  void _mostrarOpciones(
    BuildContext context,
    WidgetRef ref,
    double? radioActual,
    YumColors colors,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, -10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distancia máxima',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: radiosDisponiblesKm.map((radio) {
                final seleccionado = radio == radioActual;
                final etiqueta = radio == null ? 'Todas' : '${radio.toInt()} km';
                return GestureDetector(
                  onTap: () {
                    ref.read(radioBusquedaProvider.notifier).seleccionar(radio);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: seleccionado ? colors.terracotta : colors.cream,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: seleccionado ? colors.terracotta : colors.line,
                      ),
                    ),
                    child: Text(
                      etiqueta,
                      style: TextStyle(
                        color: seleccionado ? colors.paper : colors.inkSoft,
                        fontWeight: seleccionado
                            ? FontWeight.bold
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
