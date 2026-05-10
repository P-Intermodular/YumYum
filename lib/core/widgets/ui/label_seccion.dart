import 'package:flutter/material.dart';

import '../../theme/yum_colors.dart';

/// Etiqueta de sección reutilizable para los formularios de la app
/// (publicar plato, editar perfil…).
///
/// Soporta dos marcas independientes:
/// - `obligatorio`: añade un asterisco terracotta detrás del texto.
/// - `opcional`: añade un sufijo "· OPCIONAL" en gris suave.
///
/// Si ambos quedan en false el label es neutro (apropiado para títulos
/// informativos como "Datos de tu cuenta").
class LabelSeccion extends StatelessWidget {
  final String text;
  final bool obligatorio;
  final bool opcional;

  const LabelSeccion({
    super.key,
    required this.text,
    this.obligatorio = false,
    this.opcional = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text.toUpperCase(),
            style: TextStyle(
              color: colors.inkSoft,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          if (obligatorio)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: colors.terracottaDeep,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (opcional)
            TextSpan(
              text: '   ·   OPCIONAL',
              style: TextStyle(
                color: colors.inkSoft.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
              ),
            ),
        ],
      ),
    );
  }
}

/// Mensaje de error inline que aparece debajo de un bloque non-Form
/// (chips de categoría, switch de alérgenos, grid de fotos) cuando el
/// usuario intenta enviar el formulario sin haberlo rellenado.
class ErrorInline extends StatelessWidget {
  final String text;
  const ErrorInline({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: colors.terracottaDeep,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
