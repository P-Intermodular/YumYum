import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../domain/entities/transaccion_model.dart';
import '../../domain/repositories/transaccion_repository.dart';
import '../dtos/transaccion_dto.dart';

/// Implementación de [TransaccionRepository] usando Supabase.
class SupabaseTransaccionRepository implements TransaccionRepository {
  /// Select base con producto y contraparte para la pantalla de pedidos.
  static const _transaccionSelect = '''
    *,
    producto:producto_id(titulo),
    comprador:comprador_id(nombre),
    vendedor:vendedor_id(nombre)
  ''';

  final SupabaseClient _client;

  SupabaseTransaccionRepository(this._client);

  @override

  /// Recupera las transacciones del usuario como comprador o vendedor.
  Future<List<TransaccionModel>> obtenerTransacciones(String usuarioId) async {
    final rows = await _client
        .from(TablasSupabase.transacciones)
        .select(_transaccionSelect)
        .or('comprador_id.eq.$usuarioId,vendedor_id.eq.$usuarioId')
        .order('creado_en', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => TransaccionDto.desdeSupabase(row, usuarioId))
        .toList();
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
