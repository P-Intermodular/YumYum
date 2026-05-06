import '../entities/resultado_aceptacion_solicitud_model.dart';
import '../entities/solicitud_oferta_creada_model.dart';
import '../entities/solicitud_oferta_model.dart';

/// Contrato de negocio para el flujo de solicitudes de oferta.
abstract class SolicitudOfertaRepository {
  /// Lista las solicitudes que el usuario debe revisar como propietario.
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesRecibidas(
    String usuarioId,
  );

  /// Escucha en tiempo real las solicitudes que el usuario recibe.
  Stream<List<SolicitudOfertaModel>> escucharSolicitudesRecibidas(
    String usuarioId,
  );

  /// Lista las solicitudes creadas por el usuario autenticado.
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesEnviadas(
    String usuarioId,
  );

  /// Escucha en tiempo real las solicitudes creadas por el usuario.
  Stream<List<SolicitudOfertaModel>> escucharSolicitudesEnviadas(
    String usuarioId,
  );

  /// Crea una nueva solicitud de venta o intercambio.
  ///
  /// La [cantidad] es el número de raciones del producto solicitado. La
  /// [cantidadOfrecida] solo aplica a intercambios y representa cuántas
  /// raciones del producto propio se entregan a cambio.
  Future<SolicitudOfertaCreadaModel> crearSolicitudOferta({
    required String productoId,
    required String tipoSolicitud,
    String? productoOfrecidoId,
    String? mensaje,
    int cantidad = 1,
    int? cantidadOfrecida,
  });

  /// Acepta una solicitud y devuelve la transacción generada.
  Future<ResultadoAceptacionSolicitudModel> aceptarSolicitudOferta(
    String solicitudId,
  );

  /// Deniega una solicitud ya existente.
  Future<void> denegarSolicitudOferta(String solicitudId);

  /// Cancela una solicitud pendiente creada por el usuario autenticado.
  Future<void> cancelarSolicitudOferta(String solicitudId);
}
