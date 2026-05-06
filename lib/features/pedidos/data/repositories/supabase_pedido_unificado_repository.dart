import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/estados_app.dart';
import '../../../../core/constants/supabase_names.dart';
import '../../domain/entities/pedido_unificado_model.dart';
import '../../domain/repositories/pedido_unificado_repository.dart';

/// Implementación de [PedidoUnificadoRepository] que centraliza la consulta
/// a `solicitudes_oferta` con joins al producto, perfiles, conversación y
/// (cuando existe) la transacción asociada.
class SupabasePedidoUnificadoRepository implements PedidoUnificadoRepository {
  final SupabaseClient _client;

  SupabasePedidoUnificadoRepository(this._client);

  /// Select base usado tanto al consultar por solicitud como tras resolver la
  /// solicitud desde una transacción. Evita duplicar la query.
  static const _solicitudSelect = '''
    id,
    estado,
    tipo_solicitud,
    cantidad,
    cantidad_ofrecida,
    creado_en,
    respondido_en,
    solicitante_id,
    propietario_id,
    producto_id,
    producto:productos!solicitudes_oferta_producto_id_fkey(
      id,
      titulo,
      precio,
      tipo_oferta,
      imagenes_producto(
        url_publica,
        posicion
      )
    ),
    solicitante:perfiles!solicitudes_oferta_solicitante_id_fkey(
      id,
      nombre,
      url_avatar,
      valoracion_media,
      numero_valoraciones
    ),
    propietario:perfiles!solicitudes_oferta_propietario_id_fkey(
      id,
      nombre,
      url_avatar,
      valoracion_media,
      numero_valoraciones
    ),
    conversacion:conversaciones!conversaciones_solicitud_id_fkey(id),
    transaccion:transacciones!transacciones_solicitud_id_fkey(
      id,
      estado,
      total,
      creado_en,
      completado_en
    )
  ''';

  @override
  Future<PedidoUnificadoModel?> obtenerPorSolicitud(
    String solicitudId,
    String usuarioId,
  ) async {
    final row = await _client
        .from(TablasSupabase.solicitudesOferta)
        .select(_solicitudSelect)
        .eq('id', solicitudId)
        .maybeSingle();

    if (row == null) return null;
    return _mapear(row, usuarioId);
  }

  @override
  Future<PedidoUnificadoModel?> obtenerPorTransaccion(
    String transaccionId,
    String usuarioId,
  ) async {
    // Resolvemos la solicitud asociada y reutilizamos el mismo select.
    final transaccionRow = await _client
        .from(TablasSupabase.transacciones)
        .select('solicitud_id')
        .eq('id', transaccionId)
        .maybeSingle();

    final solicitudId = transaccionRow?['solicitud_id'] as String?;
    if (solicitudId == null) return null;

    return obtenerPorSolicitud(solicitudId, usuarioId);
  }

  PedidoUnificadoModel _mapear(
    Map<String, dynamic> solicitud,
    String usuarioId,
  ) {
    final productoJson = solicitud['producto'] as Map<String, dynamic>?;
    final solicitanteJson = solicitud['solicitante'] as Map<String, dynamic>?;
    final propietarioJson = solicitud['propietario'] as Map<String, dynamic>?;
    final esSolicitante = solicitud['solicitante_id'] == usuarioId;
    final contraparte = esSolicitante ? propietarioJson : solicitanteJson;

    // PostgREST devuelve estas relaciones como objeto cuando detecta UNIQUE
    // y como lista cuando las trata como 1:N. Aceptamos las dos formas para
    // no atarnos a la heurística.
    final transaccion = _objetoDeRelacion(solicitud['transaccion']);
    final conversacionId = _objetoDeRelacion(solicitud['conversacion'])?['id']
        as String?;

    final urlImagen = _primeraImagen(productoJson);
    final precioUnitario = _toDoubleOrNull(productoJson?['precio']);

    return PedidoUnificadoModel(
      solicitudId: solicitud['id'] as String,
      transaccionId: transaccion?['id'] as String?,
      conversacionId: conversacionId,
      estadoSolicitud:
          solicitud['estado'] as String? ?? EstadoSolicitud.pendiente,
      estadoTransaccion: transaccion?['estado'] as String?,
      tipo: solicitud['tipo_solicitud'] as String? ?? TipoOferta.venta,
      productoId: solicitud['producto_id'] as String,
      tituloProducto:
          (productoJson?['titulo'] as String?)?.trim().isNotEmpty == true
              ? productoJson!['titulo'] as String
              : 'Plato',
      urlImagenProducto: urlImagen,
      precioUnitario: precioUnitario,
      total: _toDoubleOrNull(transaccion?['total']),
      cantidad: solicitud['cantidad'] as int? ?? 1,
      cantidadOfrecida: solicitud['cantidad_ofrecida'] as int?,
      solicitanteId: solicitud['solicitante_id'] as String,
      propietarioId: solicitud['propietario_id'] as String,
      nombreContraparte:
          contraparte?['nombre'] as String? ?? 'Usuario YumYum',
      urlAvatarContraparte: contraparte?['url_avatar'] as String? ?? '',
      valoracionMediaContraparte: _toDouble(contraparte?['valoracion_media']),
      numeroValoracionesContraparte:
          contraparte?['numero_valoraciones'] as int? ?? 0,
      creadoEn:
          DateTime.tryParse(solicitud['creado_en']?.toString() ?? '') ??
              DateTime.now(),
      // El timestamp de aceptación lo damos preferentemente desde la
      // transacción (más fiable: marca el punto en que pasa a aceptada).
      // Si todavía no hay transacción, usamos respondido_en de la solicitud.
      aceptadoEn: DateTime.tryParse(
            transaccion?['creado_en']?.toString() ?? '',
          ) ??
          DateTime.tryParse(solicitud['respondido_en']?.toString() ?? ''),
      completadoEn: DateTime.tryParse(
        transaccion?['completado_en']?.toString() ?? '',
      ),
    );
  }

  String _primeraImagen(Map<String, dynamic>? productoJson) {
    final imagenes =
        (productoJson?['imagenes_producto'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
    if (imagenes.isEmpty) return '';
    final ordenadas = [...imagenes]
      ..sort((a, b) =>
          (a['posicion'] as int? ?? 0).compareTo(b['posicion'] as int? ?? 0));
    return (ordenadas.first['url_publica'] as String?) ?? '';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Devuelve el primer objeto de una relación que PostgREST puede entregar
  /// como objeto o como lista, según cómo detecte la cardinalidad.
  Map<String, dynamic>? _objetoDeRelacion(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }
}
