import '../../../../core/constants/estados_app.dart';
import '../../domain/entities/transaccion_model.dart';

/// Adapta la tabla `transacciones` al modelo de dominio de la app.
abstract final class TransaccionDto {
  /// Select base sin joins embebidos para no depender de la cache de relaciones
  /// de PostgREST entre `transacciones` y `perfiles`. La imagen y el precio
  /// del producto se resuelven en una segunda consulta agrupada (ver
  /// `SupabaseTransaccionRepository._obtenerProductosPorId`).
  static const selectBasico = '''
    id,
    solicitud_id,
    tipo,
    producto_id,
    producto_ofrecido_id,
    solicitante_id,
    propietario_id,
    total,
    estado,
    cantidad,
    cantidad_ofrecida,
    creado_en,
    completado_en
  ''';

  /// Convierte una fila enriquecida en una [TransaccionModel].
  static TransaccionModel desdeSupabase(
    Map<String, dynamic> transaccion,
    String usuarioId, {
    Map<String, dynamic>? producto,
    Map<String, dynamic>? contraparte,
  }) {
    final productoRow =
        producto ?? transaccion['producto'] as Map<String, dynamic>?;
    final esSolicitante = transaccion['solicitante_id'] == usuarioId;
    final contraparteRow = contraparte ??
        transaccion[esSolicitante ? 'propietario' : 'solicitante']
            as Map<String, dynamic>?;

    return TransaccionModel(
      id: transaccion['id'] as String,
      tipo: transaccion['tipo'] as String? ?? TipoOferta.venta,
      estado: transaccion['estado'] as String? ?? EstadoTransaccion.aceptada,
      productoId: transaccion['producto_id'] as String,
      productoOfrecidoId: transaccion['producto_ofrecido_id'] as String?,
      solicitanteId: transaccion['solicitante_id'] as String,
      propietarioId: transaccion['propietario_id'] as String,
      tituloProducto: productoRow?['titulo'] as String? ?? 'Oferta YumYum',
      nombreContraparte:
          contraparteRow?['nombre'] as String? ?? 'Usuario YumYum',
      urlAvatarContraparte: contraparteRow?['url_avatar'] as String? ?? '',
      valoracionMediaContraparte:
          _toDouble(contraparteRow?['valoracion_media']),
      numeroValoracionesContraparte:
          contraparteRow?['numero_valoraciones'] as int? ?? 0,
      total: _toDoubleOrNull(transaccion['total']),
      creadoEn: DateTime.tryParse(transaccion['creado_en']?.toString() ?? '') ??
          DateTime.now(),
      completadoEn:
          DateTime.tryParse(transaccion['completado_en']?.toString() ?? ''),
      cantidad: transaccion['cantidad'] as int? ?? 1,
      cantidadOfrecida: transaccion['cantidad_ofrecida'] as int?,
      solicitudId: transaccion['solicitud_id'] as String?,
      urlImagenProducto: _primeraImagen(productoRow),
      precioUnitario: _toDoubleOrNull(productoRow?['precio']),
    );
  }

  /// Devuelve la URL pública de la primera imagen ordenada por `posicion`.
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

  /// Normaliza valores numéricos obligatorios.
  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Normaliza importes opcionales que pueden llegar en distintos formatos.
  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
