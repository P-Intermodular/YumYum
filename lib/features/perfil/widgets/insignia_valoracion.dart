import 'package:flutter/material.dart';

/// Insignia compacta que resume la puntuación media del perfil.
class InsigniaValoracion extends StatelessWidget {
  final double valoracion;
  final int cantidad;

  const InsigniaValoracion({
    super.key,
    required this.valoracion,
    required this.cantidad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text(
            cantidad == 0
                ? 'Sin valoraciones'
                : '${valoracion.toStringAsFixed(1)} ($cantidad)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
