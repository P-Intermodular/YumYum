import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/usuario_model.dart';
import '../domain/repositories/auth_repository.dart';
import '../providers/auth_repository_provider.dart';

final autenticacionProvider =
    StateNotifierProvider<AutenticacionNotifier, AsyncValue<UsuarioModel?>>(
  (ref) {
    return AutenticacionNotifier(ref.watch(autenticacionRepositoryProvider));
  },
);

class AutenticacionNotifier extends StateNotifier<AsyncValue<UsuarioModel?>> {
  final AuthRepository _repository;

  AutenticacionNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final usuario = await _repository.obtenerUsuarioActual();
      state = AsyncValue.data(usuario);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> iniciarSesion(String correo, String password) async {
    state = const AsyncValue.loading();
    try {
      final usuario = await _repository.iniciarSesion(correo, password);
      state = AsyncValue.data(usuario);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

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

  Future<void> cerrarSesion() async {
    state = const AsyncValue.loading();
    await _repository.cerrarSesion();
    state = const AsyncValue.data(null);
  }
}
