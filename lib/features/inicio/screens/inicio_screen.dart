import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/location/ubicacion_actual.dart';
import '../../../core/location/ubicacion_actual_provider.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../producto/providers/producto_providers.dart';
import '../../producto/widgets/selector_radio_busqueda.dart';
import '../../producto/widgets/tarjeta_producto.dart';

/// Pantalla principal del feed de ofertas publicadas.
class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productosAsync = ref.watch(productosCercanosProvider);
    final ubicacionAsync = ref.watch(ubicacionActualProvider);

    return Scaffold(
      appBar: const YumYumAppBar(
        titulo: 'Inicio',
        mostrarBotonNotificaciones: true,
      ),
      body: productosAsync.when(
        data: (productos) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ubicacionActualProvider);
            ref.invalidate(productosCercanosProvider);
            await ref.read(productosCercanosProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: productos.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CabeceraProximidad(ubicacionAsync: ubicacionAsync);
              }
              final producto = productos[index - 1];
              return TarjetaProducto(producto: producto);
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(mensajeError(e))),
      ),
    );
  }
}

/// Cabecera del feed: selector de radio cuando hay ubicacion, banner con
/// accion de reintento cuando no.
class _CabeceraProximidad extends ConsumerWidget {
  final AsyncValue<UbicacionActual?> ubicacionAsync;

  const _CabeceraProximidad({required this.ubicacionAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tieneUbicacion = ubicacionAsync.valueOrNull != null;
    final radioActual = ref.watch(radioBusquedaProvider);

    if (ubicacionAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    if (tieneUbicacion) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ofertas a menos de ${radioActual.toInt()} km de ti',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            const SelectorRadioBusqueda(),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.orange.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange.shade800),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Mostrando todas las ofertas. Activa la ubicacion para ver '
                'las mas cercanas.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.invalidate(ubicacionActualProvider);
                ref.invalidate(productosCercanosProvider);
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
