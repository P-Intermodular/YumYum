import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/yum_colors.dart';

/// Un contenedor que aplica el fondo "Cream" y dibuja un sutil patrón 
/// granulado (.grain) imitando el efecto CSS del prototipo.
class YumBackground extends StatelessWidget {
  final Widget child;

  const YumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.yumColors.cream,
      child: CustomPaint(
        // Opacidad del 4% del color Ink imitando rgba(42,29,21,0.04)
        painter: _GrainPainter(color: context.yumColors.ink.withValues(alpha: 0.04)),
        child: child,
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  final Color color;

  _GrainPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[];
    
    // Dibujamos pequeños puntos espaciados simulando el entramado
    // de un mantel o papel rugoso. Se desalinean alternativamente.
    for (double y = 0; y < size.height; y += 4) {
      final offsetX = (y % 8 == 0) ? 0.0 : 2.0;
      for (double x = 0; x < size.width; x += 4) {
        points.add(Offset(x + offsetX, y));
      }
    }
    
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
