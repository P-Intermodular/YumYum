import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/constants/ubicaciones_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/location/formato_distancia.dart';
import '../../../core/location/ubicacion_actual.dart';
import '../../../core/location/ubicacion_actual_provider.dart';
import '../../../core/providers_refresher.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/dish_card_item.dart';
import '../../../core/widgets/ui/yum_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../favoritos/controllers/favorito_controller.dart';
import '../../favoritos/providers/favorito_providers.dart';
import '../../producto/domain/entities/producto_model.dart';
import '../../producto/providers/producto_providers.dart';
import '../../producto/widgets/selector_radio_busqueda.dart';

/// Pantalla de mapa que sitúa las ofertas disponibles sobre OpenStreetMap.
class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key});

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  static const double _zoomInicial = 13;

  late final MapController _mapController;
  ProviderSubscription<AsyncValue<UbicacionActual?>>? _suscripcionUbicacion;
  bool _mapaListo = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _suscripcionUbicacion = ref.listenManual<AsyncValue<UbicacionActual?>>(
      ubicacionActualProvider,
      (anterior, actual) {
        final ubicacion = actual.value;
        if (ubicacion == null || !_mapaListo) return;

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

  void _alMapaListo() {
    _mapaListo = true;
    // Workaround flutter_map: cuando el mapa se monta el viewport puede no
    // estar medido aún; el TileLayer calcula sus tiles con un rect inválido
    // y no vuelve a pedirlos hasta que la cámara cambia. Un nudge de zoom
    // imperceptible tras un par de frames fuerza ese recálculo y evita que
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
    _suscripcionUbicacion?.close();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productosCercanosProvider);
    final ubicacionAsync = ref.watch(ubicacionActualProvider);
    final ubicacionUsuario = ubicacionAsync.value;
    final radioKm = ref.watch(radioBusquedaProvider);
    final colors = context.yumColors;

    final centroInicial = ubicacionUsuario == null
        ? UbicacionesApp.madridMapaInicial
        : LatLng(ubicacionUsuario.latitud, ubicacionUsuario.longitud);

    return Scaffold(
      body: productosAsync.when(
        data: (productos) {
          final markersProductos = productos
              .map(
                (producto) => Marker(
                  point: producto.ubicacionPublica,
                  width: 80,
                  height: 80,
                  child: GestureDetector(
                    onTap: () => _mostrarDetalleProducto(context, producto),
                    child: Icon(
                      Icons.location_on,
                      color: colors.terracotta,
                      size: 44,
                      shadows: [
                        Shadow(
                          color: colors.ink.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList();

          final markersUsuario = ubicacionUsuario == null
              ? <Marker>[]
              : [
                  Marker(
                    point: LatLng(
                      ubicacionUsuario.latitud,
                      ubicacionUsuario.longitud,
                    ),
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.paper,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.ink, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: colors.ink.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: colors.ink,
                        size: 22,
                      ),
                    ),
                  ),
                ];

          // Si el usuario elige "Todas las distancias" (radioKm == null) no
          // pintamos circulo: un radio sin limite no aporta informacion
          // visual util sobre el mapa.
          final circulos = (ubicacionUsuario == null || radioKm == null)
              ? <CircleMarker>[]
              : [
                  CircleMarker(
                    point: LatLng(
                      ubicacionUsuario.latitud,
                      ubicacionUsuario.longitud,
                    ),
                    radius: radioKm * 1000,
                    useRadiusInMeter: true,
                    color: colors.terracotta.withValues(alpha: 0.10),
                    borderColor: colors.terracotta,
                    borderStrokeWidth: 1.5,
                  ),
                ];

          return Stack(
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
                  if (circulos.isNotEmpty) CircleLayer(circles: circulos),
                  MarkerLayer(markers: [...markersProductos, ...markersUsuario]),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: _SearchBarMapa()),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: colors.paper,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colors.ink.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.person_outline, color: colors.ink),
                              onPressed: () => context.push(RutasApp.perfil),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (ubicacionUsuario != null)
                        const SelectorRadioBusqueda()
                      else
                        _OverlaySinUbicacion(
                          onReintentar: () {
                            ref.refrescarUbicacionYProductosCercanos();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(mensajeError(e))),
      ),
    );
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
                    numeroValoraciones:
                        producto.propietario.numeroValoraciones,
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

class _SearchBarMapa extends StatelessWidget {
  const _SearchBarMapa();

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: colors.inkSoft, size: 22),
          const SizedBox(width: 12),
          Text(
            'Encuentra Comida Cerca',
            style: TextStyle(
              color: colors.inkSoft,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlaySinUbicacion extends StatelessWidget {
  final VoidCallback onReintentar;

  const _OverlaySinUbicacion({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    
    return YumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.location_off, color: colors.mustard),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Activa tu ubicación para centrar el mapa en ti.',
              style: TextStyle(fontSize: 13, color: colors.ink),
            ),
          ),
          TextButton(
            onPressed: onReintentar,
            child: Text('Reintentar', style: TextStyle(color: colors.terracotta, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
