import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/usuario_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../dtos/usuario_dto.dart';

/// Implementación de [AuthRepository] apoyada en Supabase Auth y Postgres.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override

  /// Valida credenciales y devuelve el perfil público asociado al usuario.
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

  /// Crea la cuenta en Supabase Auth y recupera el perfil generado por trigger.
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

  /// Cierra la sesión activa en Supabase.
  Future<void> cerrarSesion() async {
    await _client.auth.signOut();
  }

  @override

  /// Resuelve el usuario actual si ya existe una sesión persistida.
  Future<UsuarioModel?> obtenerUsuarioActual() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) return null;
    return _perfilParaUsuario(usuario.id, correoRespaldo: usuario.email);
  }

  @override

  /// Actualiza los datos del perfil del usuario en la base de datos.
  Future<UsuarioModel> actualizarPerfil(UsuarioModel usuario) async {
    final payload = UsuarioDto.aActualizacionPerfil(usuario);
    final response = await _client
        .from(TablasSupabase.perfiles)
        .update(payload)
        .eq('id', usuario.id)
        .select()
        .single();

    return UsuarioDto.desdePerfil(response);
  }

  @override

  /// Actualiza solo la ubicacion predeterminada del perfil.
  Future<UsuarioModel> actualizarUbicacionPredeterminada(
    UsuarioModel usuario,
  ) async {
    final payload = UsuarioDto.aActualizacionUbicacion(usuario);
    final response = await _client
        .from(TablasSupabase.perfiles)
        .update(payload)
        .eq('id', usuario.id)
        .select()
        .single();

    return UsuarioDto.desdePerfil(response);
  }

  Future<UsuarioModel> _perfilParaUsuario(
    String usuarioId, {
    String? correoRespaldo,
    String? nombreRespaldo,
  }) async {
    for (var intento = 0; intento < 3; intento++) {
      // El trigger que crea perfiles puede tardar unos milisegundos tras signUp.
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

    // Si el perfil todavía no está disponible, devolvemos un usuario funcional
    // para no bloquear la experiencia inicial del MVP.
    return UsuarioModel(
      id: usuarioId,
      nombre: nombreRespaldo ??
          correoRespaldo?.split('@').first ??
          'Usuario YumYum',
      correo: correoRespaldo ?? '',
      urlImagenPerfil: '',
    );
  }
}
