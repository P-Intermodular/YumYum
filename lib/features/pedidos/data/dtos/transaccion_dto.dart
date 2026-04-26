import '../../../../core/constants/estados_app.dart';
import '../../domain/entities/transaccion_model.dart';

/// Adapta la tabla `transacciones` al modelo de dominio de la app.
abstract final class TransaccionDto {
  /// Select enriquecido con producto, contraparte y datos para detalle.
  static const selectCompleto = '''
    *,
    producto:producto_id(titulo),
    comprador:comprador_id(id, nombre, url_avatar, valoracion_media, numero_valoraciones),
    vendedor:vendedor_id(id, nombre, url_avatar, valoracion_media, numero_valoraciones)
  ''';

  /// Convierte una fila enriquecida en una [TransaccionModel].
  static TransaccionModel desdeSupabase(
    Map<String, dynamic> transaccion,
    String usuarioId,
  ) {
    final producto = transaccion['producto'] as Map<String, dynamic>?;
    final esComprador = transaccion['comprador_id'] == usuarioId;
    final contraparte = transaccion[esComprador ? 'vendedor' : 'comprador']
        as Map<String, dynamic>?;

    return TransaccionModel(
      id: transaccion['id'] as String,
      tipo: transaccion['tipo'] as String? ?? TipoOferta.venta,
      estado: transaccion['estado'] as String? ?? EstadoTransaccion.aceptada,
      productoId: transaccion['producto_id'] as String,
      productoOfrecidoId: transaccion['producto_ofrecido_id'] as String?,
      compradorId: transaccion['comprador_id'] as String,
      vendedorId: transaccion['vendedor_id'] as String,
      tituloProducto: producto?['titulo'] as String? ?? 'Oferta YumYum',
      nombreContraparte: contraparte?['nombre'] as String? ?? 'Usuario YumYum',
      urlAvatarContraparte: contraparte?['url_avatar'] as String? ?? '',
      valoracionMediaContraparte:
          _toDouble(contraparte?['valoracion_media']),
      numeroValoracionesContraparte:
          contraparte?['numero_valoraciones'] as int? ?? 0,
      total: _toDoubleOrNull(transaccion['total']),
      creadoEn: DateTime.tryParse(transaccion['creado_en']?.toString() ?? '') ??
          DateTime.now(),
      completadoEn:
          DateTime.tryParse(transaccion['completado_en']?.toString() ?? ''),
    );
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
