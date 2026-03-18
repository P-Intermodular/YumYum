import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../feed/screens/feed_screen.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final userLocation = const LatLng(40.4168, -3.7038); // Mock User Location : Madrid

    return Scaffold(
      appBar: AppBar(
        title: const Text('Descubre en tu zona'),
      ),
      body: productsAsync.when(
        data: (products) {
          final markers = products.map((p) => Marker(
            point: p.location,
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () {
                // Show modal bottom sheet with product info
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(p.imageUrl),
                          ),
                          title: Text(p.title),
                          subtitle: Text(p.type == 'exchange' ? 'Intercambio' : '${p.price} €'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.pop();
                            context.push('/product/${p.id}');
                          },
                        )
                      ],
                    ),
                  )
                );
              },
              child: const Icon(
                Icons.location_on,
                color: Colors.green,
                size: 40,
              ),
            ),
          )).toList();

          return FlutterMap(
            options: MapOptions(
              initialCenter: userLocation,
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
