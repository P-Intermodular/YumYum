import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/repositories/supabase_favorito_repository.dart';
import '../domain/repositories/favorito_repository.dart';

/// Implementacion concreta del repositorio de favoritos respaldada por Supabase.
final favoritoRepositoryProvider = Provider<FavoritoRepository>((ref) {
  return SupabaseFavoritoRepository(ref.watch(supabaseClientProvider));
});

/// Stream realtime con el conjunto de IDs de productos favoritos del usuario
/// autenticado. Cuando no hay sesion devuelve un set vacio (no genera errores
/// para que la UI pueda renderizar el icono "no favorito" sin parpadeo).
final favoritosUsuarioProvider = StreamProvider<Set<String>>((ref) {
  final usuario = ref.watch(autenticacionProvider).value;
  if (usuario == null) {
    return Stream.value(const <String>{});
  }
  return ref.watch(favoritoRepositoryProvider).favoritosUsuario(usuario.id);
});

/// Indica si un producto concreto esta en la lista de favoritos del usuario
/// autenticado. Devuelve false mientras el stream carga o cuando no hay sesion.
final esFavoritoProvider = Provider.family<bool, String>((ref, productoId) {
  final favoritos = ref.watch(favoritosUsuarioProvider).value;
  return favoritos?.contains(productoId) ?? false;
});
