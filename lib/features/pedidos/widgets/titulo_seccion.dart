import 'package:flutter/material.dart';

/// Encabezado simple y consistente para agrupar bloques del panel de pedidos.
class TituloSeccion extends StatelessWidget {
  final String titulo;

  const TituloSeccion(this.titulo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F4A5B),
        ),
      ),
    );
  }
}
