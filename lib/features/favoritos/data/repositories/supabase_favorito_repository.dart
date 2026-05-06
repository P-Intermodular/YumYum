import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../domain/repositories/favorito_repository.dart';

/// Implementacion de [FavoritoRepository] respaldada por Supabase realtime.
class SupabaseFavoritoRepository implements FavoritoRepository {
  final SupabaseClient _client;

  SupabaseFavoritoRepository(this._client);

  @override
  Stream<Set<String>> favoritosUsuario(String usuarioId) {
    return _client
        .from(TablasSupabase.favoritos)
        .stream(primaryKey: const ['usuario_id', 'producto_id'])
        .eq('usuario_id', usuarioId)
        .map(
          (rows) => rows
              .map((row) => row['producto_id'] as String?)
              .whereType<String>()
              .toSet(),
        );
  }

  @override
  Future<void> anadir(String productoId) async {
    final usuarioId = _client.auth.currentUser?.id;
    if (usuarioId == null) {
      throw StateError('Sesion requerida para guardar favoritos.');
    }
    await _client.from(TablasSupabase.favoritos).insert({
      'usuario_id': usuarioId,
      'producto_id': productoId,
    });
  }

  @override
  Future<void> quitar(String productoId) async {
    final usuarioId = _client.auth.currentUser?.id;
    if (usuarioId == null) {
      throw StateError('Sesion requerida para gestionar favoritos.');
    }
    await _client
        .from(TablasSupabase.favoritos)
        .delete()
        .eq('usuario_id', usuarioId)
        .eq('producto_id', productoId);
  }
}
