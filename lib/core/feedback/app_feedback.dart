import 'package:flutter/material.dart';

import '../errors/app_exception.dart';

void mostrarError(BuildContext context, Object? error) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(mensajeError(error))),
    );
}

void mostrarExito(BuildContext context, String mensaje) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
}
