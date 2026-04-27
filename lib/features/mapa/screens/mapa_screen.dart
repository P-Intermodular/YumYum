import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/constants/ubicaciones_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/location/formato_distancia.dart';
import '../../../core/location/ubicacion_actual.dart';
import '../../../core/location/ubicacion_actual_provider.dart';
import '../../producto/domain/entities/producto_model.dart';
import '../../producto/providers/producto_providers.dart';
import '../../producto/widgets/selector_radio_busqueda.dart';
import '../../../core/widgets/yumyum_app_bar.dart';

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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // listenManual se ata al ciclo de vida del State: la suscripcion se cierra
    // en dispose sin riesgo de oyentes duplicados al rebuild.
    _suscripcionUbicacion = ref.listenManual<AsyncValue<UbicacionActual?>>(
      ubicacionActualProvider,
      (anterior, actual) {
        final ubicacion = actual.valueOrNull;
        if (ubicacion == null) return;

        final previa = anterior?.valueOrNull;
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
    final ubicacionUsuario = ubicacionAsync.valueOrNull;
    final radioKm = ref.watch(radioBusquedaProvider);

    final centroInicial = ubicacionUsuario == null
        ? UbicacionesApp.madridMapaInicial
        : LatLng(ubicacionUsuario.latitud, ubicacionUsuario.longitud);

    return Scaffold(
      appBar: const YumYumAppBar(titulo: 'Mapa'),
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
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 40,
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
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.blue.shade700, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: Colors.blue.shade700,
                        size: 22,
                      ),
                    ),
                  ),
                ];

          final circulos = ubicacionUsuario == null
              ? <CircleMarker>[]
              : [
                  CircleMarker(
                    point: LatLng(
                      ubicacionUsuario.latitud,
                      ubicacionUsuario.longitud,
                    ),
                    radius: radioKm * 1000,
                    useRadiusInMeter: true,
                    color: Colors.blue.withValues(alpha: 0.10),
                    borderColor: Colors.blue.shade700,
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
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.yumyum.app',
                  ),
                  if (circulos.isNotEmpty) CircleLayer(circles: circulos),
                  MarkerLayer(
                      markers: [...markersProductos, ...markersUsuario]),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ubicacionUsuario != null
                      ? const _OverlaySelectorRadio()
                      : _OverlaySinUbicacion(
                          onReintentar: () {
                            ref.invalidate(ubicacionActualProvider);
                            ref.invalidate(productosCercanosProvider);
                          },
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
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(producto.urlImagen),
              ),
              title: Text(producto.titulo),
              subtitle: Text(
                producto.tipo == TipoOferta.intercambio
                    ? 'Intercambio'
                    : '${producto.precio} EUR',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.pop();
                context.push(RutasApp.productoDetalle(producto.id));
              },
            ),
            if (producto.distanciaKm != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.place, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'A ${formatearDistanciaKm(producto.distanciaKm!)} de ti',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverlaySelectorRadio extends StatelessWidget {
  const _OverlaySelectorRadio();

  @override
  Widget build(BuildContext context) {
    return const SelectorRadioBusqueda();
  }
}

class _OverlaySinUbicacion extends StatelessWidget {
  final VoidCallback onReintentar;

  const _OverlaySinUbicacion({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange.shade800),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Activa tu ubicación para centrar el mapa en ti.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
