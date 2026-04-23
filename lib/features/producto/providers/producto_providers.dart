import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/producto_model.dart';
import 'producto_repository_provider.dart';

final productosProvider = FutureProvider<List<ProductoModel>>((ref) async {
  return ref.watch(productoRepositoryProvider).obtenerProductos();
});

final productoDetalleProvider =
    FutureProvider.family<ProductoModel?, String>((ref, productoId) async {
  return ref.watch(productoRepositoryProvider).obtenerProductoPorId(productoId);
});
