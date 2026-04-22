import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/producto_model.dart';
import '../repositories/producto_repository.dart';

final productosProvider = FutureProvider<List<ProductoModel>>((ref) async {
  return ref.watch(productoRepositoryProvider).obtenerProductos();
});

final productoDetalleProvider =
    FutureProvider.family<ProductoModel?, String>((ref, productoId) async {
  return ref.watch(productoRepositoryProvider).obtenerProductoPorId(productoId);
});
