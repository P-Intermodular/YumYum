/// Contrato de persistencia para los favoritos del usuario.
abstract class FavoritoRepository {
  /// Stream realtime con el conjunto de IDs de productos marcados como
  /// favoritos por el usuario indicado.
  Stream<Set<String>> favoritosUsuario(String usuarioId);

  /// Anade un producto a la lista de favoritos del usuario actual.
  Future<void> anadir(String productoId);

  /// Elimina un producto de la lista de favoritos del usuario actual.
  Future<void> quitar(String productoId);
}
