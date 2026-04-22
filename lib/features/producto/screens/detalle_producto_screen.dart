import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/yumyum_app_bar.dart';
import '../../../models/producto_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../solicitudes/repositories/solicitud_oferta_repository.dart';
import '../providers/producto_providers.dart';
import '../repositories/producto_repository.dart';

class DetalleProductoScreen extends ConsumerWidget {
  final String productoId;

  const DetalleProductoScreen({super.key, required this.productoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productoAsync = ref.watch(productoDetalleProvider(productoId));

    return Scaffold(
      appBar: const YumYumAppBar(
        titulo: 'Detalles',
        mostrarBotonVolver: true,
      ),
      body: productoAsync.when(
        data: (producto) {
          if (producto == null) {
            return const Center(child: Text('Producto no encontrado'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: 'img-${producto.id}',
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: producto.urlImagen,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              producto.titulo,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              producto.tipo == 'intercambio'
                                  ? 'Intercambio'
                                  : '${producto.precio?.toStringAsFixed(2)} EUR',
                              style: TextStyle(
                                color: producto.tipo == 'intercambio'
                                    ? Colors.purple.shade900
                                    : Colors.green.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: producto.tipo == 'intercambio'
                                ? Colors.purple.shade100
                                : Colors.green.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                              producto.propietario.urlImagenPerfil),
                        ),
                        title: Text(producto.propietario.nombre),
                        subtitle: Text(
                          producto.propietario.numeroValoraciones == 0
                              ? 'Sin valoraciones'
                              : '${producto.propietario.valoracionMedia.toStringAsFixed(1)} estrellas',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Descripcion',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        producto.descripcion,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: productoAsync.maybeWhen(
        data: (producto) {
          if (producto == null) return const SizedBox.shrink();
          final usuario = ref.watch(autenticacionProvider).value;
          final esPropietario = usuario?.id == producto.propietario.id;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: esPropietario
                    ? null
                    : () => _contactar(context, ref, producto),
                child: Text(esPropietario ? 'Tu oferta' : 'Contactar'),
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _contactar(
      BuildContext context, WidgetRef ref, ProductoModel producto) async {
    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesion')),
      );
      return;
    }

    String? productoOfrecidoId;
    final tipoSolicitud = producto.tipo == 'venta' ? 'venta' : 'intercambio';

    if (tipoSolicitud == 'intercambio') {
      final candidates = (await ref
              .read(productoRepositoryProvider)
              .obtenerMisProductosDisponibles(usuario.id))
          .where((candidate) =>
              candidate.id != producto.id && candidate.tipo == 'intercambio')
          .toList();

      if (candidates.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Publica un plato de intercambio antes de solicitar este trueque.')),
          );
        }
        return;
      }

      if (!context.mounted) return;
      final selected = await showDialog<ProductoModel>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Elige que plato ofreces'),
          children: [
            for (final candidate in candidates)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(candidate),
                child: Text(candidate.titulo),
              ),
          ],
        ),
      );

      if (selected == null) return;
      productoOfrecidoId = selected.id;
    }

    try {
      final created = await ref
          .read(solicitudOfertaRepositoryProvider)
          .crearSolicitudOferta(
            productoId: producto.id,
            tipoSolicitud: tipoSolicitud,
            productoOfrecidoId: productoOfrecidoId,
            mensaje: 'Hola, me interesa tu oferta.',
          );

      if (context.mounted) {
        context.push('/chat/${created.conversacionId}');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}
