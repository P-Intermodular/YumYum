import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/usuario_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../dtos/usuario_dto.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Future<UsuarioModel> iniciarSesion(String correo, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: correo,
      password: password,
    );

    final usuario = response.user;
    if (usuario == null) {
      throw const AppException('No se pudo iniciar sesion.');
    }

    return _perfilParaUsuario(usuario.id, correoRespaldo: usuario.email);
  }

  @override
  Future<UsuarioModel> registrarUsuario(
    String nombre,
    String correo,
    String password,
  ) async {
    final response = await _client.auth.signUp(
      email: correo,
      password: password,
      data: {'nombre': nombre},
    );

    final usuario = response.user;
    if (usuario == null) {
      throw const AppException('No se pudo crear la cuenta.');
    }

    if (response.session == null) {
      throw const AppException(
        'Cuenta creada, pero Supabase requiere confirmar el correo. '
        'Desactiva Email Confirmations para el MVP o confirma el email antes de entrar.',
      );
    }

    return _perfilParaUsuario(
      usuario.id,
      correoRespaldo: usuario.email,
      nombreRespaldo: nombre,
    );
  }

  @override
  Future<void> cerrarSesion() async {
    await _client.auth.signOut();
  }

  @override
  Future<UsuarioModel?> obtenerUsuarioActual() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) return null;
    return _perfilParaUsuario(usuario.id, correoRespaldo: usuario.email);
  }

  Future<UsuarioModel> _perfilParaUsuario(
    String usuarioId, {
    String? correoRespaldo,
    String? nombreRespaldo,
  }) async {
    for (var intento = 0; intento < 3; intento++) {
      final perfil = await _client
          .from(TablasSupabase.perfiles)
          .select()
          .eq('id', usuarioId)
          .maybeSingle();

      if (perfil != null) {
        return UsuarioDto.desdePerfil(perfil);
      }

      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    return UsuarioModel(
      id: usuarioId,
      nombre: nombreRespaldo ??
          correoRespaldo?.split('@').first ??
          'Usuario YumYum',
      correo: correoRespaldo ?? '',
      urlImagenPerfil: 'https://i.pravatar.cc/150?u=$usuarioId',
    );
  }
}
