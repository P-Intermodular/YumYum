import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../constants/ubicaciones_app.dart';
import '../location/ubicacion_actual.dart';
import '../theme/yum_colors.dart';

/// Selector visual de un punto en el mapa.
///
/// Patrón estilo Uber/Glovo: el pin queda fijo en el centro del visor y el
/// usuario arrastra el mapa para colocarlo. El callback `onPuntoCambiado`
/// se dispara durante el arrastre con el centro de la cámara, así el padre
/// siempre tiene el punto vigente sin necesidad de un evento de "fin de
/// gesto".
class SelectorUbicacionMapa extends StatelessWidget {
  final MapController mapController;
  final LatLng? ubicacionElegida;
  final UbicacionActual? ubicacionUsuario;
  final bool gpsResolviendo;
  final bool gpsFallido;
  final ValueChanged<LatLng>? onPuntoCambiado;
  final VoidCallback? onUsarUbicacionActual;
  final String? titulo;
  final String? subtitulo;
  final double altura;

  const SelectorUbicacionMapa({
    super.key,
    required this.mapController,
    required this.ubicacionElegida,
    required this.ubicacionUsuario,
    required this.gpsResolviendo,
    required this.gpsFallido,
    required this.onPuntoCambiado,
    this.onUsarUbicacionActual,
    this.titulo,
    this.subtitulo,
    this.altura = 280,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.yumColors;

    final centroInicial = ubicacionElegida ??
        (ubicacionUsuario == null
            ? UbicacionesApp.madridMapaInicial
            : LatLng(ubicacionUsuario!.latitud, ubicacionUsuario!.longitud));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titulo != null) ...[
          Text(
            titulo!,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 16,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (subtitulo != null) ...[
          Text(
            subtitulo!,
            style: TextStyle(
              color: colors.inkSoft,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (gpsFallido) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.mustard.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.mustard.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_off_rounded, color: colors.ink, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No pudimos leer tu ubicación. Arrastra el mapa para '
                    'fijar el punto.',
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.ink.withValues(alpha: 0.18),
                blurRadius: 24,
                spreadRadius: -12,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: altura,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: centroInicial,
                      initialZoom: 15,
                      onPositionChanged: (position, hasGesture) {
                        final centro = position.center;
                        if (hasGesture &&
                            centro != null &&
                            onPuntoCambiado != null) {
                          onPuntoCambiado!(centro);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.yumyum.app',
                      ),
                    ],
                  ),
                  // Pin teardrop centrado en el visor. La punta del icono
                  // queda alineada con el centro del mapa: como el ancla
                  // visual de Icons.location_on cae en su mitad inferior,
                  // desplazamos la mitad de su altura hacia arriba.
                  IgnorePointer(
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -22),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outline blanco para que el pin se lea sobre
                            // mapas oscuros o áreas con muchos detalles.
                            Icon(
                              Icons.location_on,
                              color: colors.paper,
                              size: 50,
                            ),
                            Icon(
                              Icons.location_on,
                              color: colors.terracotta,
                              size: 44,
                              shadows: [
                                Shadow(
                                  color: colors.ink.withValues(alpha: 0.40),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (gpsResolviendo)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.terracotta,
                          ),
                        ),
                      ),
                    ),
                  if (onUsarUbicacionActual != null)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Material(
                        color: colors.paper,
                        shape: StadiumBorder(
                          side: BorderSide(color: colors.line),
                        ),
                        elevation: 4,
                        shadowColor: colors.ink.withValues(alpha: 0.25),
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: onUsarUbicacionActual,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.my_location_rounded,
                                  color: colors.terracotta,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Mi ubicación',
                                  style: TextStyle(
                                    color: colors.ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
