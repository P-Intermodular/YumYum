import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../controllers/favorito_controller.dart';
import '../domain/entities/producto_guardado_model.dart';
import '../providers/favorito_providers.dart';
import '../widgets/tarjeta_plato_guardado.dart';

/// Pantalla de la mesa de favoritos del usuario.
///
/// Muestra los platos que el usuario ha marcado con el corazón en feed,
/// hero, mapa o detalle de producto, ordenados por fecha de guardado
/// descendente. Al destocar el corazón en cualquier card el plato se
/// retira de la lista (reactivo via [favoritosUsuarioProvider]).
class GuardadosScreen extends ConsumerStatefulWidget {
  const GuardadosScreen({super.key});

  @override
  ConsumerState<GuardadosScreen> createState() => _GuardadosScreenState();
}

class _GuardadosScreenState extends ConsumerState<GuardadosScreen> {
  @override
  Widget build(BuildContext context) {
    // Cuando cambia el set de IDs guardados (esta pantalla, otras pantallas
    // u otro dispositivo) refrescamos la lista resuelta.
    ref.listen(favoritosUsuarioProvider, (prev, next) {
      if (prev?.value != next.value) {
        ref.invalidate(productosGuardadosProvider);
      }
    });

    final guardadosAsync = ref.watch(productosGuardadosProvider);

    return Scaffold(
      appBar: const YumYumAppBar(
        titulo: 'Guardados',
        mostrarBotonVolver: true,
        mostrarBotonPerfil: false,
      ),
      body: YumBackground(
        child: guardadosAsync.when(
          data: (items) =>
              items.isEmpty ? _buildVacio() : _buildLista(items),
          loading: _buildSkeleton,
          error: (e, _) => _buildError(e),
        ),
      ),
    );
  }

  Future<void> _toggleFavorito(String productoId) async {
    try {
      await ref.read(favoritoControllerProvider.notifier).toggle(productoId);
    } catch (error) {
      if (mounted) mostrarError(context, error);
    }
  }

  Widget _buildLista(List<ProductoGuardadoModel> items) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          sliver: SliverToBoxAdapter(
            child: _buildContador(items.length),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final item = items[i];
                return TarjetaPlatoGuardado(
                  producto: item.producto,
                  guardadoEn: item.guardadoEn,
                  onTap: () => context.push(
                    RutasApp.productoDetalle(item.producto.id),
                  ),
                  onToggleFavorito: () => _toggleFavorito(item.producto.id),
                );
              },
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContador(int total) {
    final colors = context.yumColors;
    final etiqueta = total == 1 ? 'plato guardado' : 'platos guardados';
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        children: [
          Icon(Icons.favorite_rounded, size: 13, color: colors.terracotta),
          const SizedBox(width: 6),
          Text(
            '$total $etiqueta',
            style: TextStyle(
              fontSize: 13,
              color: colors.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.66,
      ),
      itemCount: 6,
      itemBuilder: (_, i) => _SkeletonTarjeta(delayMs: i * 80),
    );
  }

  Widget _buildVacio() {
    final colors = context.yumColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              decoration: BoxDecoration(
                color: colors.paper,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colors.terracotta.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      size: 28,
                      color: colors.terracotta,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tu mesa de favoritos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          color: colors.ink,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aún no has guardado ningún plato. Toca el corazón en un plato para verlo aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.inkSoft,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 12, color: colors.mustard),
                const SizedBox(width: 6),
                Text(
                  'Platos nuevos cada día cerca de ti',
                  style: TextStyle(
                    color: colors.inkSoft,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    final colors = context.yumColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: colors.terracottaDeep,
              ),
              const SizedBox(height: 10),
              Text(
                'No pudimos cargar tus guardados',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      color: colors.ink,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                mensajeError(error),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.inkSoft,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonTarjeta extends StatefulWidget {
  final int delayMs;
  const _SkeletonTarjeta({required this.delayMs});

  @override
  State<_SkeletonTarjeta> createState() => _SkeletonTarjetaState();
}

class _SkeletonTarjetaState extends State<_SkeletonTarjeta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        // Pulso entre 0.6 y 1.0 con delay escalonado.
        final progreso = (_controller.value +
                (widget.delayMs / 1100)) %
            1.0;
        final alpha = 0.6 + 0.4 * (1 - (progreso - 0.5).abs() * 2);
        return Opacity(
          opacity: alpha,
          child: Container(
            decoration: BoxDecoration(
              color: colors.paper,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Container(color: colors.cream2),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.cream2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 8,
                        width: 60,
                        decoration: BoxDecoration(
                          color: colors.cream2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
