import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../producto/providers/producto_providers.dart';
import '../../../core/widgets/yumyum_app_bar.dart';

class MapaScreen extends ConsumerWidget {
  const MapaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productosAsync = ref.watch(productosProvider);
    const ubicacionUsuario = LatLng(40.4168, -3.7038);

    return Scaffold(
      appBar: const YumYumAppBar(
        titulo: 'Mapa',
      ),
      body: productosAsync.when(
        data: (productos) {
          final markers = productos
              .map((producto) => Marker(
                    point: producto.ubicacion,
                    width: 80,
                    height: 80,
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (context) => Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(producto.urlImagen),
                                        ),
                                        title: Text(producto.titulo),
                                        subtitle: Text(
                                            producto.tipo == 'intercambio'
                                                ? 'Intercambio'
                                                : '${producto.precio} EUR'),
                                        trailing:
                                            const Icon(Icons.chevron_right),
                                        onTap: () {
                                          context.pop();
                                          context
                                              .push('/producto/${producto.id}');
                                        },
                                      )
                                    ],
                                  ),
                                ));
                      },
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  ))
              .toList();

          return FlutterMap(
            options: const MapOptions(
              initialCenter: ubicacionUsuario,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yumyum.app',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
