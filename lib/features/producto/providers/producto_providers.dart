import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/producto_model.dart';
import 'producto_repository_provider.dart';

/// Lista reactiva de productos visibles en el inicio y el mapa.
final productosProvider = FutureProvider<List<ProductoModel>>((ref) async {
  return ref.watch(productoRepositoryProvider).obtenerProductos();
});

/// Carga el detalle de un producto concreto a partir de su identificador.
final productoDetalleProvider =
    FutureProvider.family<ProductoModel?, String>((ref, productoId) async {
  return ref.watch(productoRepositoryProvider).obtenerProductoPorId(productoId);
});
