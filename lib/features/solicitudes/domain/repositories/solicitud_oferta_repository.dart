import '../entities/resultado_aceptacion_solicitud_model.dart';
import '../entities/solicitud_oferta_creada_model.dart';
import '../entities/solicitud_oferta_model.dart';

abstract class SolicitudOfertaRepository {
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesRecibidas(
    String usuarioId,
  );
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesEnviadas(
    String usuarioId,
  );

  Future<SolicitudOfertaCreadaModel> crearSolicitudOferta({
    required String productoId,
    required String tipoSolicitud,
    String? productoOfrecidoId,
    String? mensaje,
  });

  Future<ResultadoAceptacionSolicitudModel> aceptarSolicitudOferta(
    String solicitudId,
  );
  Future<void> denegarSolicitudOferta(String solicitudId);
}
