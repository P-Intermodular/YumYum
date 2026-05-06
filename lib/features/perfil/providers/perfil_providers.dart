import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_names.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../producto/domain/entities/producto_model.dart';
import '../../producto/providers/producto_repository_provider.dart';
import '../data/dtos/perfil_publico_dto.dart';
import '../domain/entities/perfil_publico.dart';

/// Recupera los productos activos del usuario para su pantalla de perfil.
final misProductosProvider = FutureProvider<List<ProductoModel>>((ref) async {
  final usuario = ref.watch(autenticacionProvider).value;
  if (usuario == null) return [];

  return ref
      .watch(productoRepositoryProvider)
      .obtenerMisProductosDisponibles(usuario.id);
});

/// Productos disponibles publicados por un usuario concreto.
///
/// Reutilizado tanto en mi perfil como en el perfil ajeno: el filtro de RLS
/// del select de productos ya restringe a estados públicos.
final productosDeUsuarioProvider =
    FutureProvider.family<List<ProductoModel>, String>(
        (ref, propietarioId) async {
  return ref
      .watch(productoRepositoryProvider)
      .obtenerMisProductosDisponibles(propietarioId);
});

/// Resuelve el perfil público de cualquier usuario autenticable mediante
/// la RPC `obtener_perfil_publico`.
final perfilPublicoProvider =
    FutureProvider.family<PerfilPublico, String>((ref, usuarioId) async {
  final client = ref.watch(supabaseClientProvider);
  final filas = await client.rpc(
    RpcsSupabase.obtenerPerfilPublico,
    params: {'p_usuario_id': usuarioId},
  );

  final lista = (filas as List<dynamic>?)?.cast<Map<String, dynamic>>();
  if (lista == null || lista.isEmpty) {
    throw StateError('No se encontró el perfil solicitado.');
  }

  return PerfilPublicoDto.desdeRpc(lista.first);
});
