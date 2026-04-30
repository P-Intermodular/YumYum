import '../entities/notificacion_model.dart';

/// Contrato de lectura y escritura para notificaciones internas de YumYum.
abstract class NotificacionRepository {
  /// Escucha en tiempo real las notificaciones del usuario indicado.
  Stream<List<NotificacionModel>> obtenerNotificaciones(String usuarioId);

  /// Marca todas las notificaciones no leídas del usuario como leídas.
  Future<void> marcarTodasLeidas(String usuarioId);
}
