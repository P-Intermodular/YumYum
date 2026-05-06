import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../providers/favorito_providers.dart';

/// Orquesta el toggle de favoritos desde la UI. Lanza si la sesion no esta
/// activa para que la pantalla muestre un mensaje al usuario.
final favoritoControllerProvider =
    NotifierProvider<FavoritoController, AsyncValue<void>>(
  FavoritoController.new,
);

class FavoritoController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Anade o quita el producto segun el estado actual del stream realtime.
  ///
  /// Lanza [StateError] si no hay usuario autenticado para que la UI
  /// responda con un snackbar tipo "Inicia sesion para guardar".
  Future<void> toggle(String productoId) async {
    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) {
      throw StateError('Inicia sesion para guardar favoritos.');
    }

    final favoritosActuales =
        ref.read(favoritosUsuarioProvider).value ?? const <String>{};
    final esFavorito = favoritosActuales.contains(productoId);

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(favoritoRepositoryProvider);
      if (esFavorito) {
        await repo.quitar(productoId);
      } else {
        await repo.anadir(productoId);
      }
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
