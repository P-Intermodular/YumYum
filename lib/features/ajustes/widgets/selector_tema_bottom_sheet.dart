import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tema_provider.dart';
import '../../../core/theme/yum_colors.dart';

/// Abre el selector de tema visual de la app.
Future<void> mostrarSelectorTema(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => const _SelectorTemaSheet(),
  );
}

class _SelectorTemaSheet extends ConsumerWidget {
  const _SelectorTemaSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    final temaActivo = ref.watch(temaProvider);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tema',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Solo cambian los colores de la app. Tipografías y estructuras se mantienen.',
              style: TextStyle(
                color: colors.inkSoft,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            for (final tema in YumTheme.values) ...[
              _OpcionTema(
                tema: tema,
                seleccionado: tema == temaActivo,
                onTap: () {
                  ref.read(temaProvider.notifier).seleccionar(tema);
                  Navigator.of(context).pop();
                },
              ),
              if (tema != YumTheme.values.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpcionTema extends StatelessWidget {
  final YumTheme tema;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionTema({
    required this.tema,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    // Las muestras se pintan siempre con la paleta de la opcion, no con la
    // del tema activo: asi el usuario ve a que va a cambiar.
    final preview = tema.colores;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: seleccionado ? colors.cream2 : colors.paper,
            border: Border.all(
              color: seleccionado ? colors.terracotta : colors.line,
              width: seleccionado ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _MuestrasColor(preview: preview),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tema.etiqueta,
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tema.descripcion,
                      style: TextStyle(
                        color: colors.inkSoft,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (seleccionado)
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.terracotta,
                  size: 22,
                )
              else
                Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: colors.line,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MuestrasColor extends StatelessWidget {
  final YumColors preview;

  const _MuestrasColor({required this.preview});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _Muestra(color: preview.paper, borde: preview.line),
          ),
          Positioned(
            left: 14,
            top: 0,
            child: _Muestra(color: preview.terracotta, borde: preview.line),
          ),
          Positioned(
            left: 28,
            top: 0,
            child: _Muestra(color: preview.mustard, borde: preview.line),
          ),
        ],
      ),
    );
  }
}

class _Muestra extends StatelessWidget {
  final Color color;
  final Color borde;

  const _Muestra({required this.color, required this.borde});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borde, width: 1.5),
      ),
    );
  }
}
