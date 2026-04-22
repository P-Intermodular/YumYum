import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../../models/solicitud_oferta_model.dart';

class SolicitudOfertaCreada {
  final String solicitudId;
  final String conversacionId;

  const SolicitudOfertaCreada({
    required this.solicitudId,
    required this.conversacionId,
  });
}

abstract class SolicitudOfertaRepository {
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesRecibidas(
      String usuarioId);
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesEnviadas(
      String usuarioId);

  Future<SolicitudOfertaCreada> crearSolicitudOferta({
    required String productoId,
    required String tipoSolicitud,
    String? productoOfrecidoId,
    String? mensaje,
  });

  Future<({String transaccionId, String conversacionId})>
      aceptarSolicitudOferta(String solicitudId);
  Future<void> denegarSolicitudOferta(String solicitudId);
}

final solicitudOfertaRepositoryProvider =
    Provider<SolicitudOfertaRepository>((ref) {
  return SupabaseSolicitudOfertaRepository(ref.watch(supabaseClientProvider));
});

class SupabaseSolicitudOfertaRepository implements SolicitudOfertaRepository {
  final SupabaseClient _client;

  SupabaseSolicitudOfertaRepository(this._client);

  @override
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesRecibidas(
      String usuarioId) {
    return _obtenerSolicitudes(usuarioId: usuarioId, esEntrante: true);
  }

  @override
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesEnviadas(
      String usuarioId) {
    return _obtenerSolicitudes(usuarioId: usuarioId, esEntrante: false);
  }

  @override
  Future<SolicitudOfertaCreada> crearSolicitudOferta({
    required String productoId,
    required String tipoSolicitud,
    String? productoOfrecidoId,
    String? mensaje,
  }) async {
    final response = await _client.rpc(
      'crear_solicitud_oferta',
      params: {
        'p_producto_id': productoId,
        'p_tipo_solicitud': tipoSolicitud,
        'p_producto_ofrecido_id': productoOfrecidoId,
        'p_mensaje': mensaje,
      },
    );

    final row = _firstRpcRow(response);
    return SolicitudOfertaCreada(
      solicitudId: row['solicitud_id'] as String,
      conversacionId: row['conversacion_id'] as String,
    );
  }

  @override
  Future<({String transaccionId, String conversacionId})>
      aceptarSolicitudOferta(String solicitudId) async {
    final response = await _client.rpc(
      'aceptar_solicitud_oferta',
      params: {'p_solicitud_id': solicitudId},
    );

    final row = _firstRpcRow(response);
    return (
      transaccionId: row['transaccion_id'] as String,
      conversacionId: row['conversacion_id'] as String,
    );
  }

  @override
  Future<void> denegarSolicitudOferta(String solicitudId) async {
    await _client.rpc(
      'denegar_solicitud_oferta',
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
    throw Exception('Respuesta inesperada de Supabase.');
  }

  Future<List<SolicitudOfertaModel>> _obtenerSolicitudes({
    required String usuarioId,
    required bool esEntrante,
  }) async {
    final rows = await _client
        .from('solicitudes_oferta')
        .select()
        .eq(esEntrante ? 'propietario_id' : 'solicitante_id', usuarioId)
        .order('creado_en', ascending: false);

    final solicitudes = <SolicitudOfertaModel>[];
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final contraparteId = esEntrante
          ? row['solicitante_id'] as String
          : row['propietario_id'] as String;

      solicitudes.add(
        SolicitudOfertaModel.desdePartes(
          solicitud: row,
          tituloProducto:
              await _obtenerTituloProducto(row['producto_id'] as String),
          nombreContraparte: await _obtenerNombrePerfil(contraparteId),
          esEntrante: esEntrante,
        ),
      );
    }

    return solicitudes;
  }

  Future<String> _obtenerTituloProducto(String productoId) async {
    try {
      final row = await _client
          .from('productos')
          .select('titulo')
          .eq('id', productoId)
          .maybeSingle();

      return row?['titulo'] as String? ?? 'Oferta YumYum';
    } catch (_) {
      return 'Oferta YumYum';
    }
  }

  Future<String> _obtenerNombrePerfil(String perfilId) async {
    final row = await _client
        .from('perfiles')
        .select('nombre')
        .eq('id', perfilId)
        .single();

    return row['nombre'] as String? ?? 'Usuario YumYum';
  }
}
