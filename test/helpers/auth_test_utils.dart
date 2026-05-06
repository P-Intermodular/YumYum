import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumyum/features/auth/domain/entities/usuario_model.dart';
import 'package:yumyum/features/auth/domain/repositories/auth_repository.dart';

UsuarioModel usuarioTest({String id = 'usuario-1'}) {
  return UsuarioModel(
    id: id,
    nombre: 'Ana',
    correo: '$id@example.com',
    urlImagenPerfil: '',
  );
}

SupabaseClient supabaseTestClient() {
  return SupabaseClient('https://example.supabase.co', 'anon-key');
}

class AuthRepositoryFake implements AuthRepository {
  final UsuarioModel? usuarioActual;

  const AuthRepositoryFake({required this.usuarioActual});

  @override
  Future<UsuarioModel> iniciarSesion(String correo, String password) {
    throw UnimplementedError();
  }

  @override
  Future<UsuarioModel> registrarUsuario(
    String nombre,
    String correo,
    String password,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> cerrarSesion() async {}

  @override
  Future<UsuarioModel?> obtenerUsuarioActual() async => usuarioActual;

  @override
  Future<UsuarioModel> actualizarPerfil(UsuarioModel usuario) {
    throw UnimplementedError();
  }

  @override
  Future<String> subirAvatar(String usuarioId, dynamic imagen) {
    throw UnimplementedError();
  }

  @override
  Future<UsuarioModel> actualizarUbicacionPredeterminada(UsuarioModel usuario) {
    throw UnimplementedError();
  }

  @override
  Future<void> enviarEmailRecuperacion(String correo) {
    throw UnimplementedError();
  }

  @override
  Future<void> verificarRecuperacionPassword(String tokenHash) {
    throw UnimplementedError();
  }

  @override
  Future<void> verificarCodigoRecuperacionPassword(String codigo) {
    throw UnimplementedError();
  }

  @override
  Future<void> restablecerPassword(String nuevaPassword) {
    throw UnimplementedError();
  }
}
