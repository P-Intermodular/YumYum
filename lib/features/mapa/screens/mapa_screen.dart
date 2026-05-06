import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
// `latlong2` reexporta una clase `Path` que tapa la `Path` de `dart:ui` y
// rompe `CustomClipper<Path>`. Ocultamos la suya: en este archivo solo
// necesitamos `LatLng` y `Distance`.
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/constants/ubicaciones_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/location/formato_distancia.dart';
import '../../../core/location/ubicacion_actual.dart';
import '../../../core/location/ubicacion_actual_provider.dart';
import '../../../core/providers_refresher.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/dish_card_item.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../favoritos/controllers/favorito_controller.dart';
import '../../favoritos/providers/favorito_providers.dart';
import '../../inicio/providers/feed_filtros_providers.dart';
import '../../inicio/widgets/buscador_feed.dart';
import '../../inicio/widgets/chips_categoria.dart';
import '../../inicio/widgets/filtros_feed_bottom_sheet.dart';
import '../../producto/domain/entities/producto_model.dart';
import '../../producto/providers/producto_providers.dart';
import '../providers/mapa_providers.dart';

/// Pantalla de mapa.
///
/// Reutiliza la UI y la logica de filtros del feed, pero con estado separado
/// para que explorar el mapa no cambie los filtros del inicio.
class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key});

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  static const double _zoomInicial = 13;
  static const double _umbralBuscarAquiMetros = 300;

  late final MapController _mapController;
  StreamSubscription<MapEvent>? _eventosMapa;
  ProviderSubscription<AsyncValue<UbicacionActual?>>? _suscripcionUbicacion;
  bool _mapaListo = false;
  LatLng? _centroVisual;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _eventosMapa = _mapController.mapEventStream.listen(_onEventoMapa);

    _suscripcionUbicacion = ref.listenManual<AsyncValue<UbicacionActual?>>(
      ubicacionActualProvider,
      (anterior, actual) {
        final ubicacion = actual.value;
        if (ubicacion == null || !_mapaListo) return;

        // Si el usuario ha elegido explorar otra zona ("Buscar aqui"), no
        // recentrar la camara cuando llegue una posicion GPS posterior.
        if (ref.read(centroMapaProvider) != null) return;

        final previa = anterior?.value;
        final cambio = previa == null ||
            previa.latitud != ubicacion.latitud ||
            previa.longitud != ubicacion.longitud;
        if (!cambio) return;

        _mapController.move(
          LatLng(ubicacion.latitud, ubicacion.longitud),
          _mapController.camera.zoom,
        );
      },
    );
  }

  void _onEventoMapa(MapEvent event) {
    if (!mounted) return;
    // Solo actualizamos el centro visual al terminar gestos: ahorra rebuilds
    // durante el pan y evita parpadeos del FAB.
    if (event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventDoubleTapZoomEnd ||
        event is MapEventScrollWheelZoom) {
      setState(() => _centroVisual = event.camera.center);
    }
  }

  void _alMapaListo() {
    _mapaListo = true;
    setState(() => _centroVisual = _mapController.camera.center);
    // Workaround flutter_map: cuando el mapa se monta el viewport puede no
    // estar medido aun; el TileLayer calcula sus tiles con un rect invalido
    // y no vuelve a pedirlos hasta que la camara cambia. Un nudge de zoom
    // imperceptible tras un par de frames fuerza ese recalculo y evita que
    // el usuario tenga que hacer pinch-zoom para que aparezca el mapa.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        final camera = _mapController.camera;
        _mapController.move(camera.center, camera.zoom + 0.01);
      });
    });
  }

  @override
  void dispose() {
    _eventosMapa?.cancel();
    _suscripcionUbicacion?.close();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(feedMapaFiltradoProvider);
    final ubicacionAsync = ref.watch(ubicacionActualProvider);
    final ubicacionUsuario = ubicacionAsync.value;
    final centroOverride = ref.watch(centroMapaProvider);
    final radioKm = ref.watch(mapaRadioBusquedaProvider);
    final colors = context.yumColors;

    final centroBusqueda = centroOverride ??
        (ubicacionUsuario == null
            ? null
            : LatLng(ubicacionUsuario.latitud, ubicacionUsuario.longitud));

    final centroInicial = centroBusqueda ?? UbicacionesApp.madridMapaInicial;

    final productos = productosAsync.maybeWhen(
      data: (lista) => lista,
      orElse: () => const <ProductoModel>[],
    );

    final mostrarFab = _debeMostrarBuscarAqui(centroBusqueda);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centroInicial,
              initialZoom: _zoomInicial,
              keepAlive: true,
              onMapReady: _alMapaListo,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yumyum.app',
              ),
              if (centroBusqueda != null && radioKm != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: centroBusqueda,
                      radius: radioKm * 1000,
                      useRadiusInMeter: true,
                      color: colors.terracotta.withValues(alpha: 0.10),
                      borderColor: colors.terracotta.withValues(alpha: 0.7),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final producto in productos)
                    Marker(
                      point: producto.ubicacionPublica,
                      width: 110,
                      height: 50,
                      alignment: Alignment.bottomCenter,
                      child: _MarkerPin(
                        producto: producto,
                        onTap: () => _mostrarDetalleProducto(context, producto),
                      ),
                    ),
                  if (ubicacionUsuario != null)
                    Marker(
                      point: LatLng(
                        ubicacionUsuario.latitud,
                        ubicacionUsuario.longitud,
                      ),
                      width: 30,
                      height: 30,
                      child: _MarkerUsuario(),
                    ),
                ],
              ),
            ],
          ),
          // Cada overlay se ancla con Positioned para no comer hits del mapa.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _OverlaySuperior(
              centroOverrideActivo: centroOverride != null,
            ),
          ),
          if (mostrarFab)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _BotonBuscarAqui(onTap: _onBuscarAqui),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _OverlayInferior(
              centroBusquedaActivo: centroBusqueda != null,
              ubicacionGpsDisponible: ubicacionUsuario != null,
              cargando: productosAsync.isLoading && productos.isEmpty,
              error: productosAsync.hasError
                  ? mensajeError(productosAsync.error!)
                  : null,
              totalProductos: productos.length,
              onReintentar: () => ref.refrescarUbicacionYProductosCercanos(),
            ),
          ),
        ],
      ),
    );
  }

  bool _debeMostrarBuscarAqui(LatLng? centroBusqueda) {
    final visual = _centroVisual;
    if (visual == null || !_mapaListo) return false;
    if (centroBusqueda == null) {
      // Sin GPS y sin override: el FAB sirve para fijar la zona inicial.
      return true;
    }
    final metros =
        const Distance().as(LengthUnit.Meter, visual, centroBusqueda);
    return metros > _umbralBuscarAquiMetros;
  }

  void _onBuscarAqui() {
    final centro = _centroVisual ?? _mapController.camera.center;
    ref.read(centroMapaProvider.notifier).establecer(centro);
    setState(() => _centroVisual = centro);
  }

  void _mostrarDetalleProducto(BuildContext context, ProductoModel producto) {
    final colors = context.yumColors;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cream,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, -10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
              child: Consumer(
                builder: (context, sheetRef, _) {
                  final esFavorito =
                      sheetRef.watch(esFavoritoProvider(producto.id));
                  final autenticado =
                      sheetRef.watch(autenticacionProvider).value != null;
                  return DishCardItem(
                    title: producto.titulo,
                    cookName: producto.propietario.nombre,
                    imageUrl: producto.urlImagen,
                    cookAvatarUrl: producto.propietario.urlImagenPerfil,
                    price: producto.precio ?? 0.0,
                    valoracion: producto.propietario.valoracionMedia,
                    numeroValoraciones: producto.propietario.numeroValoraciones,
                    distance: producto.distanciaKm != null
                        ? formatearDistanciaKm(producto.distanciaKm!)
                        : '---',
                    time: DateFormat('HH:mm').format(producto.creadoEn),
                    portions: producto.racionesDisponibles,
                    esFavorito: esFavorito,
                    onToggleFavorito: () => _toggleFavorito(
                      sheetContext,
                      sheetRef,
                      producto.id,
                      autenticado,
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.push(RutasApp.productoDetalle(producto.id));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorito(
    BuildContext sheetContext,
    WidgetRef sheetRef,
    String productoId,
    bool autenticado,
  ) async {
    if (!autenticado) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para guardar favoritos.')),
      );
      return;
    }
    try {
      await sheetRef
          .read(favoritoControllerProvider.notifier)
          .toggle(productoId);
    } catch (error) {
      if (sheetContext.mounted) {
        ScaffoldMessenger.of(sheetContext).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}

/// Stack superior: barra de busqueda compartida con el feed, chips de
/// categoria y, si procede, chip "Buscando en otra zona".
class _OverlaySuperior extends ConsumerWidget {
  final bool centroOverrideActivo;

  const _OverlaySuperior({required this.centroOverrideActivo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BuscadorFeed(
              scope: FiltrosProductosScope.mapa,
              onTapFiltros: () => mostrarFiltrosFeed(
                context,
                scope: FiltrosProductosScope.mapa,
                resultadosProvider: feedMapaFiltradoProvider,
              ),
            ),
            const SizedBox(height: 10),
            const ChipsCategoria(scope: FiltrosProductosScope.mapa),
            if (centroOverrideActivo) ...[
              const SizedBox(height: 10),
              const _ChipBuscandoEnOtraZona(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip discreto que avisa cuando el mapa esta mirando otra zona distinta del
/// GPS. La X devuelve la busqueda al GPS del usuario.
class _ChipBuscandoEnOtraZona extends ConsumerWidget {
  const _ChipBuscandoEnOtraZona();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => ref.read(centroMapaProvider.notifier).limpiar(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.paper,
                border: Border.all(color: colors.line),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colors.ink.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.travel_explore_rounded,
                      size: 14, color: colors.terracottaDeep),
                  const SizedBox(width: 6),
                  Text(
                    'Buscando en otra zona',
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.close_rounded, size: 14, color: colors.inkSoft),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// FAB centrado horizontalmente que aparece cuando el centro del mapa se ha
/// alejado de la zona buscada. Aplica los filtros sobre la nueva zona.
class _BotonBuscarAqui extends StatelessWidget {
  final VoidCallback onTap;

  const _BotonBuscarAqui({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return SafeArea(
      bottom: false,
      child: Padding(
        // Por encima del bloque chips/buscador (~ 48 + 10 + 38 + 8 px).
        padding: const EdgeInsets.only(top: 130),
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.terracotta,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colors.terracotta.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18, color: colors.paper),
                    const SizedBox(width: 6),
                    Text(
                      'Buscar aquí',
                      style: TextStyle(
                        color: colors.paper,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Banda inferior con selector de radio + total de ofertas + estados de error
/// o falta de GPS.
class _OverlayInferior extends ConsumerWidget {
  final bool centroBusquedaActivo;
  final bool ubicacionGpsDisponible;
  final bool cargando;
  final String? error;
  final int totalProductos;
  final VoidCallback onReintentar;

  const _OverlayInferior({
    required this.centroBusquedaActivo,
    required this.ubicacionGpsDisponible,
    required this.cargando,
    required this.error,
    required this.totalProductos,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    final mostrarBannerError = error != null;
    final mostrarBannerSinGps =
        !mostrarBannerError && !ubicacionGpsDisponible && !centroBusquedaActivo;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mostrarBannerError)
              _BannerInferior(
                icono: Icons.error_outline_rounded,
                color: colors.terracotta,
                mensaje: error!,
                accion: 'Reintentar',
                onAccion: onReintentar,
              )
            else if (mostrarBannerSinGps)
              _BannerInferior(
                icono: Icons.location_off_rounded,
                color: colors.mustard,
                mensaje:
                    'Activa tu ubicación o usa “Buscar aquí” en la zona que prefieras.',
                accion: 'Reintentar',
                onAccion: onReintentar,
              ),
            if (mostrarBannerError || mostrarBannerSinGps)
              const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ContadorOfertas(
                  total: totalProductos,
                  cargando: cargando,
                ),
                const Spacer(),
                const _SelectorRadioCompacto(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContadorOfertas extends StatelessWidget {
  final int total;
  final bool cargando;

  const _ContadorOfertas({required this.total, required this.cargando});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final texto =
        cargando ? 'Buscando…' : '$total ${total == 1 ? 'oferta' : 'ofertas'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cargando)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.terracotta,
              ),
            )
          else
            Icon(Icons.restaurant_rounded, size: 14, color: colors.oliveDeep),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: colors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de radio en formato pill compacto, alineado con el resto de
/// controles flotantes (paper + line + sombra suave).
class _SelectorRadioCompacto extends ConsumerWidget {
  const _SelectorRadioCompacto();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioActual = ref.watch(mapaRadioBusquedaProvider);
    final colors = context.yumColors;
    final texto =
        radioActual == null ? 'Cualquier' : '${radioActual.toInt()} km';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _abrirSelector(context, ref, radioActual),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.paper,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.ink.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.my_location_rounded,
                  size: 14, color: colors.terracottaDeep),
              const SizedBox(width: 6),
              Text(
                texto,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: colors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirSelector(
    BuildContext context,
    WidgetRef ref,
    double? radioActual,
  ) {
    final colors = context.yumColors;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              'Distancia máxima',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in radiosDisponiblesKm)
                  _PillRadio(
                    label: r == null ? 'Todas' : '${r.toInt()} km',
                    activa: r == radioActual,
                    onTap: () {
                      ref
                          .read(mapaRadioBusquedaProvider.notifier)
                          .seleccionar(r);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PillRadio extends StatelessWidget {
  final String label;
  final bool activa;
  final VoidCallback onTap;

  const _PillRadio({
    required this.label,
    required this.activa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activa ? colors.terracotta : colors.cream2,
          border: Border.all(
            color: activa ? colors.terracotta : colors.line,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: activa ? colors.paper : colors.ink,
            fontSize: 13,
            fontWeight: activa ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BannerInferior extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String mensaje;
  final String accion;
  final VoidCallback onAccion;

  const _BannerInferior({
    required this.icono,
    required this.color,
    required this.mensaje,
    required this.accion,
    required this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(fontSize: 12.5, color: colors.ink, height: 1.3),
            ),
          ),
          TextButton(
            onPressed: onAccion,
            style: TextButton.styleFrom(
              foregroundColor: colors.terracottaDeep,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              accion,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pin de producto: pill paper con precio (o "Trueque") y cola triangular.
/// Replica el estilo del prototipo (`MapPin3D`) y reutiliza la paleta
/// terracotta / paper para ser coherente con el resto de la app.
class _MarkerPin extends StatelessWidget {
  final ProductoModel producto;
  final VoidCallback onTap;

  const _MarkerPin({required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final esIntercambio = producto.tipo == TipoOferta.intercambio;
    final precio = producto.precio;
    final etiqueta = esIntercambio || precio == null
        ? 'Trueque'
        : (precio % 1 == 0
            ? '${precio.toInt()} €'
            : '${precio.toStringAsFixed(2).replaceAll('.', ',')} €');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.paper,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.ink.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (esIntercambio) ...[
                  Icon(Icons.swap_horiz_rounded,
                      size: 12, color: colors.terracottaDeep),
                  const SizedBox(width: 4),
                ],
                Text(
                  etiqueta,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ClipPath(
            clipper: _ColaPinClipper(),
            child: Container(
              width: 12,
              height: 7,
              color: colors.paper,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColaPinClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Marcador "tu estas aqui": punto terracotta sobre halo translucido.
class _MarkerUsuario extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colors.terracotta.withValues(alpha: 0.20),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: colors.terracotta,
            shape: BoxShape.circle,
            border: Border.all(color: colors.paper, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: colors.terracotta.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
