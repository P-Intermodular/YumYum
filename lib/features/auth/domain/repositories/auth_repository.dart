import '../entities/usuario_model.dart';

/// Contrato de autenticación de la aplicación.
///
/// Permite desacoplar la lógica de sesión de Supabase para que la UI trabaje
/// siempre contra una interfaz estable.
abstract class AuthRepository {
  /// Inicia sesión con correo y contraseña.
  Future<UsuarioModel> iniciarSesion(String correo, String password);

  /// Registra una nueva cuenta y devuelve el perfil asociado.
  Future<UsuarioModel> registrarUsuario(
    String nombre,
    String correo,
    String password,
  );

  /// Cierra la sesión actual.
  Future<void> cerrarSesion();

  /// Devuelve el usuario autenticado si existe una sesión previa.
  Future<UsuarioModel?> obtenerUsuarioActual();
}
