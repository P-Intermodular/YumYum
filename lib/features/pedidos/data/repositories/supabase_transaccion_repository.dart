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
        .select(TransaccionDto.selectCompleto)
        .or('comprador_id.eq.$usuarioId,vendedor_id.eq.$usuarioId')
        .order('creado_en', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => TransaccionDto.desdeSupabase(row, usuarioId))
        .toList();
  }

  @override

  /// Recupera una transacción concreta por su identificador.
  Future<TransaccionModel?> obtenerTransaccionPorId(
    String transaccionId,
    String usuarioId,
  ) async {
    final row = await _client
        .from(TablasSupabase.transacciones)
        .select(TransaccionDto.selectCompleto)
        .eq('id', transaccionId)
        .maybeSingle();

    if (row == null) return null;
    return TransaccionDto.desdeSupabase(row, usuarioId);
  }

  @override

  /// Ejecuta la RPC que completa una transacción aceptada.
  Future<void> completarTransaccion(String transaccionId) async {
    await _client.rpc(
      RpcsSupabase.completarTransaccion,
      params: {'p_transaccion_id': transaccionId},
    );
  }
}
