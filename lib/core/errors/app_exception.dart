class AppException implements Exception {
  final String mensaje;

  const AppException(this.mensaje);

  @override
  String toString() => mensaje;
}

String mensajeError(Object? error) {
  if (error == null) {
    return 'Ha ocurrido un error inesperado';
  }

  if (error is AppException) return error.mensaje;

  final mensaje = error.toString();
  if (mensaje.startsWith('Exception: ')) {
    return mensaje.substring('Exception: '.length);
  }

  return mensaje;
}
