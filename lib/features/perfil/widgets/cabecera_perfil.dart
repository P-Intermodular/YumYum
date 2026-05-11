import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/preferencias/avatar_preset_provider.dart';

/// Cabecera reutilizable del perfil de un usuario (propio o ajeno).
///
/// Renderiza el cover con gradiente, el avatar con overlap negativo, el
/// nombre con su badge opcional, el subtítulo (ciudad · cocina desde año) y
/// la biografía si existe.
///
/// El llamador inyecta su botón superior derecho mediante [coverAction]: un
/// engranaje en mi perfil, una bandera de reportar en perfil ajeno.
class CabeceraPerfil extends ConsumerWidget {
  final String usuarioId;
  final String nombre;
  final String urlImagen;
  final String? ciudad;
  final String? bio;
  final DateTime? creadoEn;
  final bool? esModerador;
  final Widget? coverAction;
  final Widget? leadingCoverAction;

  const CabeceraPerfil({
    super.key,
    required this.usuarioId,
    required this.nombre,
    required this.urlImagen,
    this.ciudad,
    this.bio,
    this.creadoEn,
    this.esModerador,
    this.coverAction,
    this.leadingCoverAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    final topPadding = MediaQuery.of(context).padding.top;
    final bioNormalizada = bio?.trim() ?? '';
    final preset = ref.watch(avatarPresetProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: topPadding + 164,
              width: double.infinity,
              decoration: BoxDecoration(
                // Antes saltaba de terracotta a mustard, lo que viraba a marrón
                // en la mezcla intermedia. Ahora nos quedamos en el mismo hue
                // cálido y solo modulamos la luminosidad mezclando con cream
                // hacia la esquina opuesta.
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.terracotta,
                    Color.lerp(colors.terracotta, colors.cream, 0.35)!,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CoverPatternPainter(
                        color: colors.paper.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 24,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colors.cream.withValues(alpha: 0),
                              colors.cream.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (leadingCoverAction != null)
              Positioned(
                top: topPadding + 12,
                left: 16,
                child: leadingCoverAction!,
              ),
            if (coverAction != null)
              Positioned(
                top: topPadding + 12,
                right: 16,
                child: coverAction!,
              ),
            Positioned(
              left: 20,
              bottom: -48,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.paper,
                  boxShadow: [
                    BoxShadow(
                      color: colors.ink.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: AvatarUsuario(
                  nombre: nombre,
                  identificadorColor: usuarioId,
                  urlImagen: urlImagen,
                  preset: preset,
                  radius: 44,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 58, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text(
                    nombre,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 28,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                        ),
                  ),
                  if (esModerador == true) const _BadgeModerador(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _buildSubtitulo(ciudad, creadoEn),
                style: TextStyle(
                  color: colors.inkSoft,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              if (bioNormalizada.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '«$bioNormalizada»',
                  style: TextStyle(
                    color: colors.ink.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  String _buildSubtitulo(String? ciudad, DateTime? creadoEn) {
    final ciudadTexto = ciudad == null || ciudad.trim().isEmpty
        ? 'Barrio sin indicar'
        : ciudad.trim();
    final sufijo = creadoEn != null
        ? 'Cocina desde ${creadoEn.year}'
        : 'Cocina compartida en YumYum';
    return '$ciudadTexto · $sufijo';
  }
}

class _BadgeModerador extends StatelessWidget {
  const _BadgeModerador();

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: colors.olive.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 13, color: colors.oliveDeep),
          const SizedBox(width: 4),
          Text(
            'Moderador',
            style: TextStyle(
              color: colors.oliveDeep,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Patrón de cover con motivos gastronómicos mediterráneos: bollos de pan
/// y hojas de olivo dispuestas en cuadrícula desplazada (staggered).
class _CoverPatternPainter extends CustomPainter {
  final Color color;

  const _CoverPatternPainter({required this.color});

  static const double _spacingX = 72;
  static const double _spacingY = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    int row = 0;
    for (double y = 24; y < size.height; y += _spacingY) {
      final offsetX = row.isEven ? 0.0 : _spacingX / 2;
      int col = 0;
      for (double x = -_spacingX; x < size.width + _spacingX; x += _spacingX) {
        final center = Offset(x + offsetX, y);
        if ((row + col).isEven) {
          _drawBollo(canvas, center, stroke);
        } else {
          _drawHojaOlivo(canvas, center, stroke);
        }
        col++;
      }
      row++;
    }
  }

  void _drawBollo(Canvas canvas, Offset c, Paint paint) {
    // Cuerpo oval del bollo
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 16, height: 10),
      paint,
    );
    // Dos cortes diagonales sobre la corteza
    canvas.drawLine(
      Offset(c.dx - 4, c.dy - 1),
      Offset(c.dx - 1, c.dy - 3),
      paint,
    );
    canvas.drawLine(
      Offset(c.dx, c.dy - 1),
      Offset(c.dx + 3, c.dy - 3),
      paint,
    );
  }

  void _drawHojaOlivo(Canvas canvas, Offset c, Paint paint) {
    // Hoja almendrada inclinada ~25°
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.45);
    final hoja = Path()
      ..moveTo(-8, 0)
      ..quadraticBezierTo(0, -5, 8, 0)
      ..quadraticBezierTo(0, 5, -8, 0);
    canvas.drawPath(hoja, paint);
    // Vena central
    canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CoverPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Botón circular reutilizable para la esquina superior del cover.
class CoverActionBoton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const CoverActionBoton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: colors.paper.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.ink.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: colors.ink),
          ),
        ),
      ),
    );
  }
}
