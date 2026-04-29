import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/resultado_aceptacion_solicitud_model.dart';
import '../../domain/entities/solicitud_oferta_creada_model.dart';
import '../../domain/entities/solicitud_oferta_model.dart';
import '../../domain/repositories/solicitud_oferta_repository.dart';
import '../dtos/solicitud_oferta_dto.dart';

/// Implementación de [SolicitudOfertaRepository] apoyada en RPCs y consultas SQL.
class SupabaseSolicitudOfertaRepository implements SolicitudOfertaRepository {
  /// Select base con el título del producto y la contraparte visible.
  static const _solicitudSelect = '''
    *,
    producto:productos!solicitudes_oferta_producto_id_fkey(titulo),
    solicitante:perfiles!solicitudes_oferta_solicitante_id_fkey(nombre),
    propietario:perfiles!solicitudes_oferta_propietario_id_fkey(nombre)
  ''';

  final SupabaseClient _client;

  SupabaseSolicitudOfertaRepository(this._client);

  @override

  /// Recupera las solicitudes donde el usuario actúa como propietario.
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesRecibidas(
    String usuarioId,
  ) {
    return _obtenerSolicitudes(usuarioId: usuarioId, esEntrante: true);
  }

  @override

  /// Recupera las solicitudes iniciadas por el usuario autenticado.
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesEnviadas(
    String usuarioId,
  ) {
    return _obtenerSolicitudes(usuarioId: usuarioId, esEntrante: false);
  }

  @override

  /// Ejecuta la RPC que crea solicitud, conversación y notificaciones asociadas.
  Future<SolicitudOfertaCreadaModel> crearSolicitudOferta({
    required String productoId,
    required String tipoSolicitud,
    String? productoOfrecidoId,
    String? mensaje,
  }) async {
    final response = await _client.rpc(
      RpcsSupabase.crearSolicitudOferta,
      params: {
        'p_producto_id': productoId,
        'p_tipo_solicitud': tipoSolicitud,
        'p_producto_ofrecido_id': productoOfrecidoId,
        'p_mensaje': mensaje,
      },
    );

    final row = _firstRpcRow(response);
    return SolicitudOfertaCreadaModel(
      solicitudId: row['solicitud_id'] as String,
      conversacionId: row['conversacion_id'] as String,
    );
  }

  @override

  /// Ejecuta la RPC atómica que acepta una solicitud y crea la transacción.
  Future<ResultadoAceptacionSolicitudModel> aceptarSolicitudOferta(
    String solicitudId,
  ) async {
    final response = await _client.rpc(
      RpcsSupabase.aceptarSolicitudOferta,
      params: {'p_solicitud_id': solicitudId},
    );

    final row = _firstRpcRow(response);
    return ResultadoAceptacionSolicitudModel(
      transaccionId: row['transaccion_id'] as String,
      conversacionId: row['conversacion_id'] as String,
    );
  }

  @override

  /// Ejecuta la RPC que deja la solicitud en estado denegado.
  Future<void> denegarSolicitudOferta(String solicitudId) async {
    await _client.rpc(
      RpcsSupabase.denegarSolicitudOferta,
      params: {'p_solicitud_id': solicitudId},
    );
  }

  /// Normaliza la respuesta de las RPCs a una única fila de datos.
  Map<String, dynamic> _firstRpcRow(dynamic response) {
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw const AppException('Respuesta inesperada de Supabase.');
  }

  Future<List<SolicitudOfertaModel>> _obtenerSolicitudes({
    required String usuarioId,
    required bool esEntrante,
  }) async {
    final rows = await _client
        .from(TablasSupabase.solicitudesOferta)
        .select(_solicitudSelect)
        .eq(esEntrante ? 'propietario_id' : 'solicitante_id', usuarioId)
        .order('creado_en', ascending: false);

    // El DTO decide cómo presentar la contraparte según si la solicitud es
    // entrante o enviada.
    return rows
        .cast<Map<String, dynamic>>()
        .map(
          (row) => SolicitudOfertaDto.desdeSupabase(
            solicitud: row,
            esEntrante: esEntrante,
          ),
        )
        .toList();
  }
}
