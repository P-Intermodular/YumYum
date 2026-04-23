import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/producto_providers.dart';

/// Selector horizontal del radio de busqueda por proximidad.
///
/// Solo debe pintarse cuando la ubicacion del usuario esta disponible; la
/// pantalla que lo contiene decide mostrarlo u ocultarlo.
class SelectorRadioBusqueda extends ConsumerWidget {
  const SelectorRadioBusqueda({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioActual = ref.watch(radioBusquedaProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (final radio in radiosDisponiblesKm)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text('${radio.toInt()} km'),
                selected: radio == radioActual,
                onSelected: (seleccionado) {
                  if (!seleccionado) return;
                  ref.read(radioBusquedaProvider.notifier).state = radio;
                },
              ),
            ),
        ],
      ),
    );
  }
}
