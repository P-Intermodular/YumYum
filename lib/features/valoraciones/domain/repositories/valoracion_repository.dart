/// Contrato de creación de valoraciones sobre transacciones completadas.
abstract class ValoracionRepository {
  /// Inserta una valoración y su comentario opcional.
  Future<void> crearValoracion({
    required String transaccionId,
    required String valoradorId,
    required String valoradoId,
    String? productoValoradoId,
    required int puntuacion,
    String? comentario,
  });
}
