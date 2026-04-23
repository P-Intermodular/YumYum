import 'package:flutter/material.dart';

import '../errors/app_exception.dart';

/// Muestra un mensaje de error reutilizando el [ScaffoldMessenger] activo.
void mostrarError(BuildContext context, Object? error) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(mensajeError(error))),
    );
}

/// Muestra un mensaje de éxito breve en la parte inferior de la pantalla.
void mostrarExito(BuildContext context, String mensaje) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
}
