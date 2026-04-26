import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/usuario_model.dart';
import '../domain/repositories/auth_repository.dart';
import '../providers/auth_repository_provider.dart';

/// Estado global de autenticación de la aplicación.
///
/// Arranca resolviendo la sesión actual y expone operaciones de entrada,
/// registro y cierre de sesión para el resto de la UI.
final autenticacionProvider =
    StateNotifierProvider<AutenticacionNotifier, AsyncValue<UsuarioModel?>>(
  (ref) {
    return AutenticacionNotifier(ref.watch(autenticacionRepositoryProvider));
  },
);

/// Orquesta los flujos de autenticación desde la capa application.
class AutenticacionNotifier extends StateNotifier<AsyncValue<UsuarioModel?>> {
  final AuthRepository _repository;

  AutenticacionNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  /// Carga la sesión persistida al iniciar la app.
  Future<void> _init() async {
    try {
      final usuario = await _repository.obtenerUsuarioActual();
      state = AsyncValue.data(usuario);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Inicia sesión y actualiza el estado compartido de autenticación.
  Future<void> iniciarSesion(String correo, String password) async {
    state = const AsyncValue.loading();
    try {
      final usuario = await _repository.iniciarSesion(correo, password);
      state = AsyncValue.data(usuario);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Registra un nuevo usuario en Supabase Auth y carga su perfil público.
  Future<void> registrarUsuario(
    String nombre,
    String correo,
    String password,
  ) async {
    state = const AsyncValue.loading();
    try {
      final usuario =
          await _repository.registrarUsuario(nombre, correo, password);
      state = AsyncValue.data(usuario);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Cierra la sesión activa y deja la app en estado anónimo.
  Future<void> cerrarSesion() async {
    state = const AsyncValue.loading();
    await _repository.cerrarSesion();
    state = const AsyncValue.data(null);
  }

  /// Actualiza los datos del perfil del usuario y refresca el estado.
  Future<void> actualizarPerfil(UsuarioModel usuario) async {
    try {
      final usuarioActualizado = await _repository.actualizarPerfil(usuario);
      state = AsyncValue.data(usuarioActualizado);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Actualiza solo la ubicacion predeterminada y refresca el estado.
  Future<void> actualizarUbicacionPredeterminada(UsuarioModel usuario) async {
    try {
      final actualizado =
          await _repository.actualizarUbicacionPredeterminada(usuario);
      state = AsyncValue.data(actualizado);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
