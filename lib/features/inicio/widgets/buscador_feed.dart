import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/yum_colors.dart';
import '../providers/feed_filtros_providers.dart';

/// Barra de búsqueda + botón de filtros del feed.
///
/// Replica figma (`screens-a.tsx#L99-L107`): pill paper 48 con icono lupa +
/// input + botón cuadrado oscuro 48×48 a la derecha. El botón de filtros
/// muestra un punto terracotta cuando hay filtros activos.
class BuscadorFeed extends ConsumerStatefulWidget {
  final VoidCallback onTapFiltros;

  const BuscadorFeed({super.key, required this.onTapFiltros});

  @override
  ConsumerState<BuscadorFeed> createState() => _BuscadorFeedState();
}

class _BuscadorFeedState extends ConsumerState<BuscadorFeed> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(busquedaQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final filtrosActivos = ref.watch(filtrosActivosCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colors.paper,
                border: Border.all(color: colors.line),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: colors.inkSoft),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (valor) =>
                          ref.read(busquedaQueryProvider.notifier).set(valor),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Busca lentejas, tortilla, tarta…',
                        hintStyle:
                            TextStyle(color: colors.inkSoft, fontSize: 14),
                      ),
                      style: TextStyle(color: colors.ink, fontSize: 14),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _controller.clear();
                        ref.read(busquedaQueryProvider.notifier).set('');
                        setState(() {});
                      },
                      child: Icon(Icons.close, size: 16, color: colors.inkSoft),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: widget.onTapFiltros,
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.ink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.tune_rounded,
                    color: colors.paper,
                    size: 18,
                  ),
                ),
                if (filtrosActivos > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colors.terracotta,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.cream, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
