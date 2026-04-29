import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../domain/entities/transaccion_model.dart';
import '../../domain/repositories/transaccion_repository.dart';
import '../dtos/transaccion_dto.dart';

/// Implementación de [TransaccionRepository] usando Supabase.
class SupabaseTransaccionRepository implements TransaccionRepository {
  final SupabaseClient _client;

  SupabaseTransaccionRepository(this._client);

  @override

  /// Recupera las transacciones del usuario como comprador o vendedor.
  Future<List<TransaccionModel>> obtenerTransacciones(String usuarioId) async {
    final rows = await _client
        .from(TablasSupabase.transacciones)
        .select(TransaccionDto.selectBasico)
        .or('comprador_id.eq.$usuarioId,vendedor_id.eq.$usuarioId')
        .order('creado_en', ascending: false);

    return _mapearTransacciones(
      rows.cast<Map<String, dynamic>>().toList(),
      usuarioId,
    );
  }

  @override

  /// Recupera una transacción concreta por su identificador.
  Future<TransaccionModel?> obtenerTransaccionPorId(
    String transaccionId,
    String usuarioId,
  ) async {
    final row = await _client
        .from(TablasSupabase.transacciones)
        .select(TransaccionDto.selectBasico)
        .eq('id', transaccionId)
        .maybeSingle();

    if (row == null) return null;
    final transacciones = await _mapearTransacciones([row], usuarioId);
    return transacciones.single;
  }

  @override

  /// Ejecuta la RPC que completa una transacción aceptada.
  Future<void> completarTransaccion(String transaccionId) async {
    await _client.rpc(
      RpcsSupabase.completarTransaccion,
      params: {'p_transaccion_id': transaccionId},
    );
  }

  Future<List<TransaccionModel>> _mapearTransacciones(
    List<Map<String, dynamic>> rows,
    String usuarioId,
  ) async {
    if (rows.isEmpty) return const [];

    final productos = await _obtenerProductosPorId(
      rows.map((row) => row['producto_id'] as String),
    );
    final perfiles = await _obtenerPerfilesPorId(
      rows.expand(
        (row) => [
          row['comprador_id'] as String,
          row['vendedor_id'] as String,
        ],
      ),
    );

    return rows.map((row) {
      final esComprador = row['comprador_id'] == usuarioId;
      final contraparteId =
          row[esComprador ? 'vendedor_id' : 'comprador_id'] as String;

      return TransaccionDto.desdeSupabase(
        row,
        usuarioId,
        producto: productos[row['producto_id']],
        contraparte: perfiles[contraparteId],
      );
    }).toList();
  }

  Future<Map<String, Map<String, dynamic>>> _obtenerProductosPorId(
    Iterable<String> ids,
  ) async {
    final idsUnicos = ids.toSet().toList();
    if (idsUnicos.isEmpty) return const {};

    final rows = await _client
        .from(TablasSupabase.productos)
        .select('id, titulo')
        .inFilter('id', idsUnicos);

    return {
      for (final row in rows.cast<Map<String, dynamic>>())
        row['id'] as String: row,
    };
  }

  Future<Map<String, Map<String, dynamic>>> _obtenerPerfilesPorId(
    Iterable<String> ids,
  ) async {
    final idsUnicos = ids.toSet().toList();
    if (idsUnicos.isEmpty) return const {};

    final rows = await _client
        .from(TablasSupabase.perfiles)
        .select('id, nombre, url_avatar, valoracion_media, numero_valoraciones')
        .inFilter('id', idsUnicos);

    return {
      for (final row in rows.cast<Map<String, dynamic>>())
        row['id'] as String: row,
    };
  }
}
