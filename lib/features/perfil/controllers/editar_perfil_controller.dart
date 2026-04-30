import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../auth/controllers/auth_controller.dart';

import '../../auth/providers/auth_repository_provider.dart';

/// Controlador responsable de la actualización del perfil de usuario y avatar.
final editarPerfilControllerProvider =
    NotifierProvider.autoDispose<EditarPerfilController, AsyncValue<void>>(
  EditarPerfilController.new,
);

class EditarPerfilController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Sube la imagen de avatar (si existe) y actualiza los datos del usuario.
  Future<void> actualizarPerfil({
    required String nombre,
    required String ciudad,
    required List<String> preferencias,
    File? nuevoAvatar,
  }) async {
    final keepAlive = ref.keepAlive();
    final usuarioActual = ref.read(autenticacionProvider).value;

    if (usuarioActual == null) {
      keepAlive.close();
      throw const AppException('Debes iniciar sesión para editar tu perfil.');
    }

    if (nombre.trim().isEmpty) {
      keepAlive.close();
      throw const AppException('El nombre no puede estar vacío.');
    }

    state = const AsyncValue.loading();

    try {
      final repository = ref.read(autenticacionRepositoryProvider);
      String urlAvatar = usuarioActual.urlImagenPerfil;

      // 1. Si hay una nueva imagen, la subimos primero al bucket.
      if (nuevoAvatar != null) {
        urlAvatar = await repository.subirAvatar(usuarioActual.id, nuevoAvatar);
      }

      // 2. Preparamos el modelo actualizado.
      final usuarioActualizado = usuarioActual.copyWith(
        nombre: nombre.trim(),
        ciudad: ciudad.trim(),
        preferencias: preferencias,
        urlImagenPerfil: urlAvatar,
      );

      // 3. Persistimos los cambios y refrescamos la sesión local
      // usando el AutenticacionNotifier (que se encarga de ambas cosas).
      await ref.read(autenticacionProvider.notifier).actualizarPerfil(usuarioActualizado);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // Lanzamos el error para que la UI pueda mostrar el AppFeedback
    } finally {
      keepAlive.close();
    }
  }
}
