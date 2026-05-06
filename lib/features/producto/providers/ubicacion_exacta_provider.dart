import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'producto_repository_provider.dart';

/// Obtiene la ubicacion exacta de un producto via la RPC protegida.
final ubicacionExactaProvider =
    FutureProvider.autoDispose.family<LatLng?, String>((ref, productoId) async {
  return ref
      .watch(productoRepositoryProvider)
      .obtenerUbicacionExactaProducto(productoId);
});
