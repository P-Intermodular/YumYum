import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/entities/usuario_model.dart';
import '../domain/repositories/auth_repository.dart';
import '../providers/auth_repository_provider.dart';

/// Estado global de autenticación de la aplicación.
///
/// Arranca resolviendo la sesión actual y expone operaciones de entrada,
/// registro y cierre de sesión para el resto de la UI.
final autenticacionProvider =
    StateNotifierProvider<AutenticacionNotifier, EstadoAutenticacion>(
  (ref) {
    return AutenticacionNotifier(
      ref.watch(autenticacionRepositoryProvider),
      ref.watch(supabaseClientProvider),
    );
  },
);

/// Estado completo de autenticación.
///
/// Mantiene el usuario como [AsyncValue] para conservar carga/error, y añade
/// una señal reactiva para distinguir la sesión temporal de recovery.
class EstadoAutenticacion {
  final AsyncValue<UsuarioModel?> usuario;
  final bool enRecuperacion;

  const EstadoAutenticacion({
    required this.usuario,
    this.enRecuperacion = false,
  });

  const EstadoAutenticacion.inicial()
      : usuario = const AsyncValue.loading(),
        enRecuperacion = false;

  EstadoAutenticacion copyWith({
    AsyncValue<UsuarioModel?>? usuario,
    bool? enRecuperacion,
  }) {
    return EstadoAutenticacion(
      usuario: usuario ?? this.usuario,
      enRecuperacion: enRecuperacion ?? this.enRecuperacion,
    );
  }

  /// Getters de compatibilidad para los consumidores existentes.
  bool get isLoading => usuario.isLoading;
  bool get hasError => usuario.hasError;
  Object? get error => usuario.error;
  UsuarioModel? get value => usuario.value;
  UsuarioModel? get valueOrNull => usuario.valueOrNull;
}

/// Orquesta los flujos de autenticación desde la capa application.
class AutenticacionNotifier extends StateNotifier<EstadoAutenticacion> {
  final AuthRepository _repository;
  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _suscripcion;

  AutenticacionNotifier(this._repository, this._client)
      : super(const EstadoAutenticacion.inicial()) {
    _suscripcion = _client.auth.onAuthStateChange.listen(
      _manejarCambioAutenticacion,
    );
    _init();
  }

  /// Carga la sesión persistida al iniciar la app.
  Future<void> _init() async {
    await _sincronizarUsuarioActual();
  }

  /// Reacciona a los cambios de sesión publicados por Supabase Auth.
  Future<void> _manejarCambioAutenticacion(AuthState authState) async {
    switch (authState.event) {
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        await _sincronizarUsuarioActual();
        break;
      case AuthChangeEvent.passwordRecovery:
        await _sincronizarUsuarioActual(enRecuperacion: true);
        break;
      case AuthChangeEvent.signedOut:
        state = state.copyWith(
          usuario: const AsyncValue.data(null),
          enRecuperacion: false,
        );
        break;
      default:
        break;
    }
  }

  /// Resuelve el usuario actual sin pasar por un estado de carga global.
  Future<void> _sincronizarUsuarioActual({bool? enRecuperacion}) async {
    try {
      final usuario = await _repository.obtenerUsuarioActual();
      state = state.copyWith(
        usuario: AsyncValue.data(usuario),
        enRecuperacion: enRecuperacion ?? state.enRecuperacion,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        usuario: AsyncValue.error(error, stackTrace),
        enRecuperacion: enRecuperacion ?? state.enRecuperacion,
      );
    }
  }

  /// Inicia sesión y actualiza el estado compartido de autenticación.
  Future<void> iniciarSesion(String correo, String password) async {
    state = state.copyWith(
      usuario: const AsyncValue.loading(),
      enRecuperacion: false,
    );
    try {
      final usuario = await _repository.iniciarSesion(correo, password);
      state = state.copyWith(
        usuario: AsyncValue.data(usuario),
        enRecuperacion: false,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        usuario: AsyncValue.error(error, stackTrace),
        enRecuperacion: false,
      );
    }
  }

  /// Registra un nuevo usuario en Supabase Auth y carga su perfil público.
  Future<void> registrarUsuario(
    String nombre,
    String correo,
    String password,
  ) async {
    state = state.copyWith(
      usuario: const AsyncValue.loading(),
      enRecuperacion: false,
    );
    try {
      final usuario =
          await _repository.registrarUsuario(nombre, correo, password);
      state = state.copyWith(
        usuario: AsyncValue.data(usuario),
        enRecuperacion: false,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        usuario: AsyncValue.error(error, stackTrace),
        enRecuperacion: false,
      );
    }
  }

  /// Cierra la sesión activa y deja la app en estado anónimo.
  Future<void> cerrarSesion() async {
    await _repository.cerrarSesion();
  }

  /// Marca que la sesión actual pertenece al flujo temporal de recovery.
  void activarRecuperacionPassword() {
    state = state.copyWith(enRecuperacion: true);
  }

  /// Limpia el modo recovery sin tocar la sesión actual.
  void limpiarRecuperacionPassword() {
    state = state.copyWith(enRecuperacion: false);
  }

  /// Cancela recovery y cierra la sesión temporal abierta por Supabase.
  Future<void> cancelarRecuperacionPassword() async {
    state = state.copyWith(enRecuperacion: false);
    await _repository.cerrarSesion();
  }

  /// Actualiza los datos del perfil del usuario y refresca el estado.
  Future<void> actualizarPerfil(UsuarioModel usuario) async {
    try {
      final usuarioActualizado = await _repository.actualizarPerfil(usuario);
      state = state.copyWith(usuario: AsyncValue.data(usuarioActualizado));
    } catch (error, stackTrace) {
      state = state.copyWith(usuario: AsyncValue.error(error, stackTrace));
      rethrow;
    }
  }

  /// Actualiza solo la ubicacion predeterminada y refresca el estado.
  Future<void> actualizarUbicacionPredeterminada(UsuarioModel usuario) async {
    try {
      final actualizado =
          await _repository.actualizarUbicacionPredeterminada(usuario);
      state = state.copyWith(usuario: AsyncValue.data(actualizado));
    } catch (error, stackTrace) {
      state = state.copyWith(usuario: AsyncValue.error(error, stackTrace));
      rethrow;
    }
  }

  /// Guarda la nueva contraseña y cierra la sesión temporal de recovery.
  Future<void> restablecerPassword(String nuevaPassword) async {
    await _repository.restablecerPassword(nuevaPassword);
    state = state.copyWith(enRecuperacion: false);
    await _repository.cerrarSesion();
  }

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }
}
