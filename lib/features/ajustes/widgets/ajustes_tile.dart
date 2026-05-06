import 'package:flutter/material.dart';

import '../../../core/theme/yum_colors.dart';

/// Item individual de un [AjustesGrupo].
///
/// Reproduce el patrón figma: cuadrado con icono a la izquierda, etiqueta,
/// valor actual opcional como hint y chevron al final.
class AjustesTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final bool ultimo;

  const AjustesTile({
    super.key,
    required this.icon,
    required this.label,
    this.hint,
    this.onTap,
    this.ultimo = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: ultimo
              ? null
              : Border(bottom: BorderSide(color: colors.line)),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: colors.cream2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: colors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (hint != null) ...[
              Flexible(
                child: Text(
                  hint!,
                  style: TextStyle(
                    color: colors.inkSoft,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right, size: 18, color: colors.inkSoft),
          ],
        ),
      ),
    );
  }
}
