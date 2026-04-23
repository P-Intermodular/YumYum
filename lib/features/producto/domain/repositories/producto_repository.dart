import 'dart:typed_data';

import '../entities/producto_model.dart';

/// Contrato de persistencia para el catálogo de productos.
abstract class ProductoRepository {
  /// Recupera las ofertas disponibles visibles en el inicio y en el mapa.
  Future<List<ProductoModel>> obtenerProductos();

  /// Busca un producto concreto por su identificador.
  Future<ProductoModel?> obtenerProductoPorId(String productoId);

  /// Recupera los productos activos del propietario autenticado.
  Future<List<ProductoModel>> obtenerMisProductosDisponibles(
    String propietarioId,
  );

  /// Crea un producto y, opcionalmente, sube su imagen asociada.
  Future<ProductoModel> crearProducto(
    ProductoModel producto, {
    Uint8List? bytesImagen,
    String extensionImagen,
  });
}
