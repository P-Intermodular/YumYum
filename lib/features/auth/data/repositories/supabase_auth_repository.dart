import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/rutas_app.dart';
import '../../../../core/constants/supabase_names.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/supabase/supabase_config.dart';
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
      throw const AppException('No se pudo iniciar sesión.');
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
    await _client
        .from(TablasSupabase.perfiles)
        .update(payload)
        .eq('id', usuario.id);

    return _perfilParaUsuario(usuario.id, correoRespaldo: usuario.correo);
  }

  @override

  /// Actualiza solo la ubicacion predeterminada del perfil.
  Future<UsuarioModel> actualizarUbicacionPredeterminada(
    UsuarioModel usuario,
  ) async {
    final payload = UsuarioDto.aActualizacionUbicacion(usuario);
    await _client
        .from(TablasSupabase.perfiles)
        .update(payload)
        .eq('id', usuario.id);

    return _perfilParaUsuario(usuario.id, correoRespaldo: usuario.correo);
  }

  Future<UsuarioModel> _perfilParaUsuario(
    String usuarioId, {
    String? correoRespaldo,
    String? nombreRespaldo,
  }) async {
    for (var intento = 0; intento < 3; intento++) {
      // El trigger que crea perfiles puede tardar unos milisegundos tras signUp.
      final perfil =
          await _client.rpc(RpcsSupabase.obtenerMiPerfil).maybeSingle();

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

  @override

  /// Delega la recuperación de contraseña en Supabase Auth.
  Future<void> enviarEmailRecuperacion(String correo) async {
    await _client.auth.resetPasswordForEmail(
      correo.trim(),
      redirectTo: _resolverRedirectRecuperacion(),
    );
  }

  @override

  /// Verifica el token hash del enlace y abre una sesión recovery válida.
  Future<void> verificarRecuperacionPassword(String tokenHash) async {
    try {
      final response = await _client.auth.verifyOTP(
        type: OtpType.recovery,
        tokenHash: tokenHash,
      );
      if (response.session == null || response.user == null) {
        throw const AppException(
          'El enlace de recuperación ya no es válido. Solicita uno nuevo.',
        );
      }
    } on AuthException catch (error) {
      throw AppException(error.message);
    }
  }

  @override

  /// Intercambia el codigo PKCE del enlace y abre una sesión recovery válida.
  Future<void> verificarCodigoRecuperacionPassword(String codigo) async {
    try {
      await _client.auth.exchangeCodeForSession(codigo);
      if (_client.auth.currentUser == null) {
        throw const AppException(
          'El enlace de recuperación ya no es válido. Solicita uno nuevo.',
        );
      }
    } on AuthException catch (error) {
      throw AppException(error.message);
    }
  }

  @override

  /// Actualiza la contraseña dentro de una sesión de recuperación válida.
  Future<void> restablecerPassword(String nuevaPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: nuevaPassword),
      );
    } on AuthSessionMissingException {
      throw const AppException(
        'El enlace de recuperación ya no es válido. Solicita uno nuevo.',
      );
    } on AuthException catch (error) {
      throw AppException(error.message);
    }
  }

  /// Construye el destino de vuelta para el enlace de recuperación.
  String _resolverRedirectRecuperacion() {
    const appBaseUrl = SupabaseConfig.appBaseUrl;

    if (kIsWeb) {
      final baseUrl = appBaseUrl.isNotEmpty ? appBaseUrl : Uri.base.origin;
      return Uri.parse(baseUrl)
          .resolve(RutasApp.restablecerPassword)
          .toString();
    }

    return 'yumyum://restablecer-password';
  }
}
