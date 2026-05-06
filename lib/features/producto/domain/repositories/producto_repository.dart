import 'package:latlong2/latlong.dart';

import '../../controllers/datos_publicacion_producto.dart';
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

  /// Crea un producto y, opcionalmente, sube sus imagenes en orden. La
  /// primera imagen de [imagenes] queda como portada (`posicion = 0`).
  ///
  /// La [ubicacionExacta] queda guardada para entregarsela mas tarde a quien
  /// participe en una transaccion aceptada del producto. Solo se persiste, no
  /// se devuelve en lecturas estandar del catalogo.
  Future<ProductoModel> crearProducto(
    ProductoModel producto, {
    required LatLng ubicacionExacta,
    List<ImagenSeleccionada> imagenes = const [],
  });

  /// Recupera la ubicacion exacta de un producto cuando el usuario actual es
  /// propietario o participante autorizado de una transaccion en curso.
  Future<LatLng?> obtenerUbicacionExactaProducto(String productoId);

  /// Lista las imagenes ya persistidas de un producto, ordenadas por
  /// posicion. Necesario al entrar en modo edicion para pre-rellenar el grid.
  Future<List<ImagenSeleccionada>> obtenerImagenesProducto(String productoId);

  /// Aplica una edicion al producto: actualiza campos, sube las imagenes
  /// nuevas a Storage e elimina las que el usuario haya quitado del grid.
  ///
  /// Las posiciones de las filas en `imagenes_producto` se reasignan en
  /// orden consecutivo `[0..n-1]` tras la operacion para que la portada
  /// (posicion 0) sea siempre la primera del array de UI.
  Future<void> actualizarProducto({
    required String productoId,
    required ProductoModel producto,
    required List<ImagenSeleccionada> imagenesFinales,
    required List<String> idsImagenesAEliminar,
  });

  /// Elimina un producto. Devuelve `true` si fue DELETE real (la app debe
  /// limpiar los blobs en Storage), `false` si fue soft delete por tener
  /// historial asociado.
  Future<bool> eliminarProducto(String productoId);
}
