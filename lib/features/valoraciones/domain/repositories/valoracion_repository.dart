abstract class ValoracionRepository {
  Future<void> crearValoracion({
    required String transaccionId,
    required String valoradorId,
    required String valoradoId,
    String? productoValoradoId,
    required int puntuacion,
    String? comentario,
  });
}
