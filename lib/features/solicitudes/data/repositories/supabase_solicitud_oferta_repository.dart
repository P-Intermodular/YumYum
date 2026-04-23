import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/resultado_aceptacion_solicitud_model.dart';
import '../../domain/entities/solicitud_oferta_creada_model.dart';
import '../../domain/entities/solicitud_oferta_model.dart';
import '../../domain/repositories/solicitud_oferta_repository.dart';
import '../dtos/solicitud_oferta_dto.dart';

class SupabaseSolicitudOfertaRepository implements SolicitudOfertaRepository {
  static const _solicitudSelect = '''
    *,
    producto:producto_id(titulo),
    solicitante:solicitante_id(nombre),
    propietario:propietario_id(nombre)
  ''';

  final SupabaseClient _client;

  SupabaseSolicitudOfertaRepository(this._client);

  @override
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesRecibidas(
    String usuarioId,
  ) {
    return _obtenerSolicitudes(usuarioId: usuarioId, esEntrante: true);
  }

  @override
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesEnviadas(
    String usuarioId,
  ) {
    return _obtenerSolicitudes(usuarioId: usuarioId, esEntrante: false);
  }

  @override
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
  Future<void> denegarSolicitudOferta(String solicitudId) async {
    await _client.rpc(
      RpcsSupabase.denegarSolicitudOferta,
      params: {'p_solicitud_id': solicitudId},
    );
  }

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
