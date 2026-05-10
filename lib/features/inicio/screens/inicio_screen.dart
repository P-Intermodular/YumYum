import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/location/ubicacion_actual_provider.dart';
import '../../../core/providers_refresher.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/boton_ia_global.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../producto/domain/entities/producto_model.dart';
import '../../producto/providers/producto_providers.dart';
import '../providers/feed_filtros_providers.dart';
import '../widgets/buscador_feed.dart';
import '../widgets/cabecera_inicio.dart';
import '../widgets/chips_categoria.dart';
import '../widgets/fila_plato.dart';
import '../widgets/filtros_feed_bottom_sheet.dart';
import '../widgets/hero_plato.dart';
import '../widgets/seccion_titulo.dart';

const _kBottomNavOverlayHeight = 120.0;
const _kBotonSubirGap = 16.0;

/// Feed principal: cabecera personal + búsqueda + chips + plato destacado +
/// recomendados. Replica la estética del prototipo-figma `FeedScreen`.
class InicioScreen extends ConsumerStatefulWidget {
  const InicioScreen({super.key});

  @override
  ConsumerState<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends ConsumerState<InicioScreen> {
  final _scrollController = ScrollController();
  bool _mostrarBotonSubir = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_actualizarBotonSubir);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_actualizarBotonSubir)
      ..dispose();
    super.dispose();
  }

  void _actualizarBotonSubir() {
    final debeMostrarse = _scrollController.offset > 420;
    if (debeMostrarse == _mostrarBotonSubir) return;

    setState(() {
      _mostrarBotonSubir = debeMostrarse;
    });
  }

  Future<void> _subirAlInicio() async {
    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedFiltradoProvider);
    final ubicacion = ref.watch(ubicacionActualProvider);
    final usuario = ref.watch(autenticacionProvider).value;
    final colors = context.yumColors;

    return Scaffold(
      body: YumBackground(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                ref.refrescarUbicacionYProductosCercanos();
                await ref.read(productosCercanosProvider.future);
              },
              child: feed.when(
                data: (lista) => _buildScroll(
                  context: context,
                  ref: ref,
                  productos: lista,
                  ciudadUsuario: usuario?.ciudad,
                  tieneUbicacion: ubicacion.value != null,
                  ubicacionCargando: ubicacion.isLoading,
                  colors: colors,
                ),
                loading: () => _buildScroll(
                  context: context,
                  ref: ref,
                  productos: const [],
                  ciudadUsuario: usuario?.ciudad,
                  tieneUbicacion: ubicacion.value != null,
                  ubicacionCargando: ubicacion.isLoading,
                  colors: colors,
                  cargando: true,
                ),
                error: (e, st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      mensajeError(e),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.inkSoft),
                    ),
                  ),
                ),
              ),
            ),
            _BotonSubirInicio(
              visible: _mostrarBotonSubir,
              onTap: _subirAlInicio,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScroll({
    required BuildContext context,
    required WidgetRef ref,
    required List<ProductoModel> productos,
    required String? ciudadUsuario,
    required bool tieneUbicacion,
    required bool ubicacionCargando,
    required YumColors colors,
    bool cargando = false,
  }) {
    final padding = MediaQuery.of(context).padding;
    final query = ref.watch(busquedaQueryProvider);
    final hayFiltros =
        query.isNotEmpty || ref.watch(filtrosActivosCountProvider) > 0;

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: padding.top + 4,
        bottom: _kBottomNavOverlayHeight + 64,
      ),
      children: [
        CabeceraInicio(ciudad: ciudadUsuario),
        const SizedBox(height: 14),
        BuscadorFeed(onTapFiltros: () => mostrarFiltrosFeed(context)),
        const SizedBox(height: 14),
        const ChipsCategoria(),
        if (!tieneUbicacion && !ubicacionCargando) ...[
          const SizedBox(height: 14),
          _BannerSinUbicacion(
            onReintentar: () => ref.refrescarUbicacionYProductosCercanos(),
          ),
        ],
        if (cargando)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Center(
              child: CircularProgressIndicator(color: colors.terracotta),
            ),
          )
        else if (productos.isEmpty)
          _EstadoVacio(hayFiltros: hayFiltros)
        else ...[
          const SeccionTitulo(titulo: 'Cerca de ti'),
          HeroPlato(producto: productos.first),
          if (productos.length > 1) ...[
            // El nombre antiguo "Recomendados" prometía un sistema de
            // recomendación que no existe: la lista solo está ordenada por
            // el criterio activo (recientes por defecto). El CTA "Ordenar"
            // duplicaba el botón de filtros del buscador, así que también
            // lo retiramos.
            const SeccionTitulo(titulo: 'Otras ofertas cerca'),
            for (final producto in productos.skip(1)) ...[
              FilaPlato(producto: producto),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ],
    );
  }
}

class _BotonSubirInicio extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;

  const _BotonSubirInicio({
    required this.visible,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final padding = MediaQuery.of(context).padding;

    return Positioned(
      right: 20,
      bottom: padding.bottom + _kBottomNavOverlayHeight + _kBotonSubirGap,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: AnimatedScale(
            scale: visible ? 1 : 0.88,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Tooltip(
              message: 'Volver arriba',
              child: Semantics(
                button: true,
                label: 'Volver arriba del feed',
                child: Material(
                  color: colors.terracotta,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  elevation: 8,
                  shadowColor: colors.ink.withValues(alpha: 0.22),
                  child: InkWell(
                    onTap: onTap,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: colors.paper,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerSinUbicacion extends StatelessWidget {
  final VoidCallback onReintentar;

  const _BannerSinUbicacion({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.mustard.withValues(alpha: 0.18),
          border: Border.all(color: colors.mustard.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off_outlined,
                color: colors.terracottaDeep, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Mostrando todas las ofertas. Activa la ubicación para verlas más cerca.',
                style: TextStyle(fontSize: 12.5),
              ),
            ),
            TextButton(
              onPressed: onReintentar,
              child: Text(
                'Reintentar',
                style: TextStyle(
                  color: colors.terracottaDeep,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoVacio extends ConsumerWidget {
  final bool hayFiltros;

  const _EstadoVacio({required this.hayFiltros});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: colors.cream2,
              shape: BoxShape.circle,
              border: Border.all(color: colors.line),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.restaurant_menu_outlined,
              size: 36,
              color: colors.olive,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hayFiltros ? 'Sin resultados' : 'Aún no hay ofertas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hayFiltros
                ? 'Prueba con otra búsqueda o ajusta los filtros.'
                : 'Cuando algún vecino publique un plato lo verás aquí.',
            style: TextStyle(
              fontSize: 13,
              color: colors.inkSoft,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (hayFiltros) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(busquedaQueryProvider.notifier).set('');
                ref.read(categoriaSeleccionadaProvider.notifier).set(null);
                ref.read(etiquetasSeleccionadasProvider.notifier).limpiar();
                ref
                    .read(ordenacionFeedProvider.notifier)
                    .set(OrdenFeed.recientes);
                ref.read(radioBusquedaProvider.notifier).seleccionar(null);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.terracotta,
                foregroundColor: colors.paper,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Limpiar filtros',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
