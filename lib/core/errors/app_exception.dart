import 'error_traductor.dart';

/// Excepción ligera de dominio para mostrar errores controlados en la UI.
class AppException implements Exception {
  final String mensaje;

  const AppException(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Convierte cualquier error capturado en un mensaje legible para el usuario.
///
/// Prioridad:
/// 1. [AppException] — ya contiene mensaje de dominio.
/// 2. [ErrorTraductor] — traduce excepciones de Supabase.
/// 3. Fallback genérico.
String mensajeError(Object? error) {
  if (error == null) {
    return 'Ha ocurrido un error inesperado';
  }

  if (error is AppException) return error.mensaje;

  final traducido = ErrorTraductor.traducir(error);
  if (traducido != null) return traducido;

  final mensaje = error.toString();
  if (mensaje.startsWith('Exception: ')) {
    return mensaje.substring('Exception: '.length);
  }

  return mensaje;
}

