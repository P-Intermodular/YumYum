import '../entities/usuario_model.dart';

abstract class AuthRepository {
  Future<UsuarioModel> iniciarSesion(String correo, String password);
  Future<UsuarioModel> registrarUsuario(
    String nombre,
    String correo,
    String password,
  );
  Future<void> cerrarSesion();
  Future<UsuarioModel?> obtenerUsuarioActual();
}
