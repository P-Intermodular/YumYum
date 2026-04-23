import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../producto/providers/producto_providers.dart';
import '../../producto/widgets/tarjeta_producto.dart';

/// Pantalla principal del feed de ofertas publicadas.
class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productosAsyncValue = ref.watch(productosProvider);

    return Scaffold(
      appBar: const YumYumAppBar(
        titulo: 'Inicio',
        mostrarBotonNotificaciones: true,
      ),
      body: productosAsyncValue.when(
        data: (productos) => RefreshIndicator(
          // Fuerza una nueva consulta al catálogo para sincronizar el feed.
          onRefresh: () async => ref.refresh(productosProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
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
