import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../../producto/data/dtos/producto_dto.dart';
import '../../../producto/data/repositories/supabase_producto_repository.dart';
import '../../domain/entities/producto_guardado_model.dart';
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
  Future<List<ProductoGuardadoModel>> obtenerProductosGuardados(
    String usuarioId,
  ) async {
    // Una sola roundtrip: la tabla `favoritos` con embed de `productos`
    // siguiendo el mismo select base que el feed para que el mapeo del DTO
    // produzca un ProductoModel idéntico al del resto de pantallas.
    final rows = await _client
        .from(TablasSupabase.favoritos)
        .select(
          'creado_en, productos!inner(${SupabaseProductoRepository.productoSelect})',
        )
        .eq('usuario_id', usuarioId)
        .order('creado_en', ascending: false);

    return rows.cast<Map<String, dynamic>>().map((row) {
      final productoJson = row['productos'] as Map<String, dynamic>;
      final producto = ProductoDto.desdeSupabase(productoJson);
      final guardadoEn =
          DateTime.tryParse(row['creado_en']?.toString() ?? '') ??
              DateTime.now();
      return ProductoGuardadoModel(
        producto: producto,
        guardadoEn: guardadoEn,
      );
    }).toList(growable: false);
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
