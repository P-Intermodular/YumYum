import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import '../entities/producto_model.dart';

/// Contrato de persistencia para el catálogo de productos.
abstract class ProductoRepository {
  /// Recupera las ofertas disponibles visibles en el inicio y en el mapa.
  Future<List<ProductoModel>> obtenerProductos();

  /// Recupera las ofertas disponibles ordenadas por proximidad al usuario.
  Future<List<ProductoModel>> obtenerProductosCercanos({
    required double latitud,
    required double longitud,
    double radioKm = 10,
    int limite = 50,
  });

  /// Busca un producto concreto por su identificador.
  Future<ProductoModel?> obtenerProductoPorId(String productoId);

  /// Recupera los productos activos del propietario autenticado.
  Future<List<ProductoModel>> obtenerMisProductosDisponibles(
    String propietarioId,
  );

  /// Crea un producto y, opcionalmente, sube su imagen asociada.
  ///
  /// La [ubicacionExacta] queda guardada para entregarsela mas tarde a quien
  /// participe en una transaccion aceptada del producto. Solo se persiste, no
  /// se devuelve en lecturas estandar del catalogo.
  Future<ProductoModel> crearProducto(
    ProductoModel producto, {
    required LatLng ubicacionExacta,
    Uint8List? bytesImagen,
    String extensionImagen,
  });

  /// Recupera la ubicacion exacta de un producto cuando el usuario actual es
  /// propietario o participante autorizado de una transaccion en curso.
  Future<LatLng?> obtenerUbicacionExactaProducto(String productoId);
}
