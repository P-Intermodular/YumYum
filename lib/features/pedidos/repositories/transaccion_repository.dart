import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../../models/transaccion_model.dart';

abstract class TransaccionRepository {
  Future<List<TransaccionModel>> obtenerTransacciones(String usuarioId);
  Future<void> completarTransaccion(String transaccionId);
}

final transaccionRepositoryProvider = Provider<TransaccionRepository>((ref) {
  return SupabaseTransaccionRepository(ref.watch(supabaseClientProvider));
});

class SupabaseTransaccionRepository implements TransaccionRepository {
  final SupabaseClient _client;

  SupabaseTransaccionRepository(this._client);

  @override
  Future<List<TransaccionModel>> obtenerTransacciones(String usuarioId) async {
    final rows = await _client
        .from('transacciones')
        .select()
        .or('comprador_id.eq.$usuarioId,vendedor_id.eq.$usuarioId')
        .order('creado_en', ascending: false);

    final transacciones = <TransaccionModel>[];
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final tituloProducto =
          await _obtenerTituloProducto(row['producto_id'] as String);
      final contraparteId = row['comprador_id'] == usuarioId
          ? row['vendedor_id'] as String
          : row['comprador_id'] as String;
      final nombreContraparte = await _obtenerNombrePerfil(contraparteId);

      transacciones.add(
        TransaccionModel.desdePartes(
          transaccion: row,
          tituloProducto: tituloProducto,
          nombreContraparte: nombreContraparte,
        ),
      );
    }

    return transacciones;
  }

  @override
  Future<void> completarTransaccion(String transaccionId) async {
    await _client.rpc(
      'completar_transaccion',
      params: {'p_transaccion_id': transaccionId},
    );
  }

  Future<String> _obtenerTituloProducto(String productoId) async {
    final row = await _client
        .from('productos')
        .select('titulo')
        .eq('id', productoId)
        .single();
    return row['titulo'] as String? ?? 'Oferta YumYum';
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
