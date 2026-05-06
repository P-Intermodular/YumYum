import '../entities/valoracion_model.dart';

/// Contrato de lectura y escritura de valoraciones sobre transacciones.
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

  /// Devuelve la valoración del usuario para una transacción, si existe.
  Future<ValoracionModel?> obtenerValoracionUsuario(
    String transaccionId,
    String valoradorId,
  );

  /// Lista las valoraciones recibidas por un usuario, ordenadas por fecha.
  Future<List<ValoracionModel>> obtenerValoracionesRecibidas(String valoradoId);
}
