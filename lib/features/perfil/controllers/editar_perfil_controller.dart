import 'dart:typed_data';

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
  ///
  /// Si [quitarAvatar] es `true` se ignora [nuevoAvatar] y se persiste el
  /// `urlImagenPerfil` vacío para que la UI vuelva al placeholder con
  /// iniciales.
  Future<void> actualizarPerfil({
    required String nombre,
    required String ciudad,
    required String bio,
    required List<String> preferencias,
    required List<String> alergenos,
    Uint8List? nuevoAvatarBytes,
    String? nuevoAvatarExtension,
    bool quitarAvatar = false,
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

      if (quitarAvatar) {
        // Quitar foto: vacía la URL. No tocamos el blob en Storage para no
        // romper avatares cacheados en chats antiguos; lo limpia un job de
        // mantenimiento si hace falta.
        urlAvatar = '';
      } else if (nuevoAvatarBytes != null) {
        urlAvatar = await repository.subirAvatar(
          usuarioActual.id,
          nuevoAvatarBytes,
          extension: (nuevoAvatarExtension ?? 'jpg'),
        );
      }

      final usuarioActualizado = usuarioActual.copyWith(
        nombre: nombre.trim(),
        ciudad: ciudad.trim(),
        bio: bio.trim(),
        preferencias: preferencias,
        alergenos: alergenos,
        urlImagenPerfil: urlAvatar,
      );

      await ref
          .read(autenticacionProvider.notifier)
          .actualizarPerfil(usuarioActualizado);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    } finally {
      keepAlive.close();
    }
  }
}
