import '../../../../core/constants/estados_app.dart';
import '../../domain/entities/solicitud_oferta_model.dart';

/// Convierte filas de Supabase en [SolicitudOfertaModel].
abstract final class SolicitudOfertaDto {
  /// Adapta una fila enriquecida al punto de vista del usuario actual.
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
      cantidad: solicitud['cantidad'] as int? ?? 1,
      cantidadOfrecida: solicitud['cantidad_ofrecida'] as int?,
      urlImagenProducto: _primeraImagen(producto),
      precioUnitario: _toDoubleOrNull(producto?['precio']),
    );
  }

  /// Devuelve la URL pública de la primera imagen del plato (la de menor
  /// `posicion`). Si el join no trajo imágenes, devuelve cadena vacía para
  /// que la card pinte un fallback.
  static String _primeraImagen(Map<String, dynamic>? productoJson) {
    final imagenes =
        (productoJson?['imagenes_producto'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
    if (imagenes.isEmpty) return '';
    final ordenadas = [...imagenes]
      ..sort((a, b) =>
          (a['posicion'] as int? ?? 0).compareTo(b['posicion'] as int? ?? 0));
    return (ordenadas.first['url_publica'] as String?) ?? '';
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
