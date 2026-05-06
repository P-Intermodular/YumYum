import 'package:flutter/material.dart';

import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';

/// Cabecera reutilizable del perfil de un usuario (propio o ajeno).
///
/// Renderiza el cover con gradiente, el avatar con overlap negativo, el
/// nombre con su badge opcional, el subtítulo (ciudad · cocina desde año) y
/// la biografía si existe.
///
/// El llamador inyecta su botón superior derecho mediante [coverAction]: un
/// engranaje en mi perfil, una bandera de reportar en perfil ajeno.
class CabeceraPerfil extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final topPadding = MediaQuery.of(context).padding.top;
    final bioNormalizada = bio?.trim() ?? '';

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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.terracotta, colors.mustard],
                ),
              ),
              child: CustomPaint(
                painter: _CoverPatternPainter(
                  color: colors.paper.withValues(alpha: 0.15),
                ),
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
                  if (esModerador != null)
                    _BadgeVerificado(esModerador: esModerador!),
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
                  bioNormalizada,
                  style: TextStyle(
                    color: colors.ink,
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

class _BadgeVerificado extends StatelessWidget {
  final bool esModerador;

  const _BadgeVerificado({required this.esModerador});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final texto = esModerador ? 'Moderador' : 'Verificada';
    final icono =
        esModerador ? Icons.shield_outlined : Icons.verified_outlined;

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
          Icon(icono, size: 13, color: colors.oliveDeep),
          const SizedBox(width: 4),
          Text(
            texto,
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

class _CoverPatternPainter extends CustomPainter {
  final Color color;

  const _CoverPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (double y = 18; y < size.height; y += 32) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 48) {
        path.quadraticBezierTo(x + 24, y - 12, x + 48, y);
      }
      canvas.drawPath(path, paint);
    }
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
