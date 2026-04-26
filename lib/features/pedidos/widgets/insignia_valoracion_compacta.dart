import 'package:flutter/material.dart';

/// Insignia inline que muestra la puntuación media y cantidad de valoraciones.
class InsigniaValoracionCompacta extends StatelessWidget {
  final double valoracion;
  final int cantidad;

  const InsigniaValoracionCompacta({
    super.key,
    required this.valoracion,
    required this.cantidad,
  });

  @override
  Widget build(BuildContext context) {
    if (cantidad == 0) {
      return Text(
        'Sin valoraciones',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text(
          '${valoracion.toStringAsFixed(1)} ($cantidad)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.amber.shade900,
          ),
        ),
      ],
    );
  }
}
