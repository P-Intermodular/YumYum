import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/repositories/supabase_favorito_repository.dart';
import '../domain/entities/producto_guardado_model.dart';
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

/// Lista completa de productos guardados por el usuario autenticado para
/// alimentar la pantalla "Guardados". Cuando no hay sesión, lista vacía.
///
/// La pantalla escucha [favoritosUsuarioProvider] (stream realtime) e invalida
/// este provider al cambiar el set de IDs, así cubrimos: destocar desde la
/// propia pantalla, y guardar/destocar desde otras pantallas o dispositivos.
final productosGuardadosProvider =
    FutureProvider.autoDispose<List<ProductoGuardadoModel>>((ref) async {
  final usuario = ref.watch(autenticacionProvider).value;
  if (usuario == null) return const [];
  return ref
      .watch(favoritoRepositoryProvider)
      .obtenerProductosGuardados(usuario.id);
});
