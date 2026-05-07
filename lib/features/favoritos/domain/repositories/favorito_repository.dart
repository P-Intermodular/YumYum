import '../entities/producto_guardado_model.dart';

/// Contrato de persistencia para los favoritos del usuario.
abstract class FavoritoRepository {
  /// Stream realtime con el conjunto de IDs de productos marcados como
  /// favoritos por el usuario indicado.
  Stream<Set<String>> favoritosUsuario(String usuarioId);

  /// Lista completa de productos guardados por el usuario, ordenados por
  /// fecha de guardado descendente. Cada elemento incluye el producto y la
  /// fecha en la que se marcó como favorito (necesaria para la pantalla
  /// "Guardados").
  Future<List<ProductoGuardadoModel>> obtenerProductosGuardados(
    String usuarioId,
  );

  /// Anade un producto a la lista de favoritos del usuario actual.
  Future<void> anadir(String productoId);

  /// Elimina un producto de la lista de favoritos del usuario actual.
  Future<void> quitar(String productoId);
}
