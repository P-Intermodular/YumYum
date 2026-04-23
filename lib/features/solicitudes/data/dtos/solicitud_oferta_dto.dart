import '../../../../core/constants/estados_app.dart';
import '../../domain/entities/solicitud_oferta_model.dart';

abstract final class SolicitudOfertaDto {
  static SolicitudOfertaModel desdeSupabase({
    required Map<String, dynamic> solicitud,
    required bool esEntrante,
  }) {
    final producto = solicitud['producto'] as Map<String, dynamic>?;
    final contraparte = solicitud[esEntrante ? 'solicitante' : 'propietario']
        as Map<String, dynamic>?;

    return SolicitudOfertaModel(
      id: solicitud['id'] as String,
      tipoSolicitud: solicitud['tipo_solicitud'] as String? ?? TipoOferta.venta,
      estado: solicitud['estado'] as String? ?? EstadoSolicitud.pendiente,
      productoId: solicitud['producto_id'] as String,
      productoOfrecidoId: solicitud['producto_ofrecido_id'] as String?,
      tituloProducto: producto?['titulo'] as String? ?? 'Oferta YumYum',
      nombreContraparte: contraparte?['nombre'] as String? ?? 'Usuario YumYum',
      mensaje: solicitud['mensaje'] as String?,
      creadoEn: DateTime.tryParse(solicitud['creado_en']?.toString() ?? '') ??
          DateTime.now(),
      esEntrante: esEntrante,
    );
  }
}
