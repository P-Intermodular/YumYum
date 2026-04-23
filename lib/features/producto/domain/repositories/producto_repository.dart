import 'dart:typed_data';

import '../entities/producto_model.dart';

abstract class ProductoRepository {
  Future<List<ProductoModel>> obtenerProductos();
  Future<ProductoModel?> obtenerProductoPorId(String productoId);
  Future<List<ProductoModel>> obtenerMisProductosDisponibles(
    String propietarioId,
  );
  Future<ProductoModel> crearProducto(
    ProductoModel producto, {
    Uint8List? bytesImagen,
    String extensionImagen,
  });
}
