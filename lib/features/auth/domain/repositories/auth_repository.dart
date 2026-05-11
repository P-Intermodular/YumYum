import 'dart:typed_data';

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

  /// Actualiza los datos del perfil del usuario en la base de datos.
  Future<UsuarioModel> actualizarPerfil(UsuarioModel usuario);

  /// Sube un nuevo avatar para el usuario y devuelve la URL pública.
  Future<String> subirAvatar(
    String usuarioId,
    Uint8List bytes, {
    required String extension,
  });

  /// Actualiza solo la ubicacion predeterminada del perfil.
  Future<UsuarioModel> actualizarUbicacionPredeterminada(UsuarioModel usuario);

  /// Actualiza solo el mapa de preferencias de notificaciones del usuario.
  /// Se usa desde la pantalla Ajustes → Notificaciones, que aplica los
  /// cambios al instante (toggle por toggle) sin botón "Guardar".
  Future<UsuarioModel> actualizarPreferenciasNotificaciones(
    String usuarioId,
    Map<String, bool> preferencias,
  );

  /// Envía un correo de recuperación de contraseña al email indicado.
  Future<void> enviarEmailRecuperacion(String correo);

  /// Verifica el token hash del correo antes de mostrar el formulario recovery.
  Future<void> verificarRecuperacionPassword(String tokenHash);

  /// Intercambia el codigo PKCE del correo por una sesion recovery valida.
  Future<void> verificarCodigoRecuperacionPassword(String codigo);

  /// Actualiza la contraseña del usuario autenticado dentro del flujo recovery.
  Future<void> restablecerPassword(String nuevaPassword);
}
