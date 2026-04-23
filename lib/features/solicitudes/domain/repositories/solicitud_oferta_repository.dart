import '../entities/resultado_aceptacion_solicitud_model.dart';
import '../entities/solicitud_oferta_creada_model.dart';
import '../entities/solicitud_oferta_model.dart';

/// Contrato de negocio para el flujo de solicitudes de oferta.
abstract class SolicitudOfertaRepository {
  /// Lista las solicitudes que el usuario debe revisar como propietario.
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesRecibidas(
    String usuarioId,
  );

  /// Lista las solicitudes creadas por el usuario autenticado.
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesEnviadas(
    String usuarioId,
  );

  /// Crea una nueva solicitud de venta o intercambio.
  Future<SolicitudOfertaCreadaModel> crearSolicitudOferta({
    required String productoId,
    required String tipoSolicitud,
    String? productoOfrecidoId,
    String? mensaje,
  });

  /// Acepta una solicitud y devuelve la transacción generada.
  Future<ResultadoAceptacionSolicitudModel> aceptarSolicitudOferta(
    String solicitudId,
  );

  /// Deniega una solicitud ya existente.
  Future<void> denegarSolicitudOferta(String solicitudId);
}
