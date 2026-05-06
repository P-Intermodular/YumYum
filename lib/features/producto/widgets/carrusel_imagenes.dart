import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/yum_colors.dart';

/// Carrusel deslizable de fotos del producto.
///
/// Mantiene aspect 4:3 en el nivel mas externo para que cualquier `Stack`
/// padre pueda medirlo sin ambiguedad. Conserva la `Hero` animation sobre
/// la primera imagen (compatibilidad con el feed) y muestra un indicador de
/// puntos pill cuando hay mas de una foto.
class CarruselImagenes extends StatefulWidget {
  /// URLs de las imagenes en orden de visualizacion. La primera es la
  /// portada y la unica que comparte la `Hero` tag.
  final List<String> urls;

  /// Tag de Hero compartida con el feed/listados (suele ser `img-{producto.id}`).
  final String heroTag;

  const CarruselImagenes({
    super.key,
    required this.urls,
    required this.heroTag,
  });

  @override
  State<CarruselImagenes> createState() => _CarruselImagenesState();
}

class _CarruselImagenesState extends State<CarruselImagenes> {
  final _controller = PageController();
  int _indice = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final urls = widget.urls;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: urls.isEmpty
          ? Container(color: colors.cream2)
          : Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: urls.length,
                  onPageChanged: (i) => setState(() => _indice = i),
                  itemBuilder: (context, index) {
                    final imagen = CachedNetworkImage(
                      imageUrl: urls[index],
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Container(color: colors.cream2),
                    );
                    if (index == 0) {
                      return Hero(tag: widget.heroTag, child: imagen);
                    }
                    return imagen;
                  },
                ),
                if (urls.length > 1)
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _IndicadorDots(
                        total: urls.length,
                        actual: _indice,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _IndicadorDots extends StatelessWidget {
  final int total;
  final int actual;

  const _IndicadorDots({required this.total, required this.actual});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.paper.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == actual ? 8 : 6,
              height: i == actual ? 8 : 6,
              decoration: BoxDecoration(
                color: i == actual
                    ? colors.ink
                    : colors.ink.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
