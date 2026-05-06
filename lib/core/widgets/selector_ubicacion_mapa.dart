import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../constants/ubicaciones_app.dart';
import '../location/ubicacion_actual.dart';
import '../theme/yum_colors.dart';

/// Mapa interactivo donde el usuario fija un punto exacto en el mapa.
///
/// Cada toque mueve el marker a la coordenada tocada. flutter_map no admite
/// markers arrastrables nativamente, asi que usamos tap-to-place.
class SelectorUbicacionMapa extends StatelessWidget {
  final MapController mapController;
  final LatLng? ubicacionElegida;
  final UbicacionActual? ubicacionUsuario;
  final bool gpsResolviendo;
  final bool gpsFallido;
  final ValueChanged<LatLng>? onTap;
  final String titulo;
  final String subtitulo;

  const SelectorUbicacionMapa({
    super.key,
    required this.mapController,
    required this.ubicacionElegida,
    required this.ubicacionUsuario,
    required this.gpsResolviendo,
    required this.gpsFallido,
    required this.onTap,
    this.titulo = 'Punto exacto',
    this.subtitulo = 'Toca el mapa para indicar el punto exacto.',
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
        Text(
          titulo,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 16,
            color: colors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitulo,
          style: TextStyle(
            color: colors.inkSoft,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        if (gpsFallido)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                    'No pudimos leer tu ubicación. Mueve el mapa y toca para fijar el punto.',
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
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: centroInicial,
                    initialZoom: 15,
                    onTap: onTap == null
                        ? null
                        : (_, punto) => onTap!(punto),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.yumyum.app',
                    ),
                    if (ubicacionElegida != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: ubicacionElegida!,
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.location_on,
                              color: colors.terracotta,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (gpsResolviendo)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colors.terracotta),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
