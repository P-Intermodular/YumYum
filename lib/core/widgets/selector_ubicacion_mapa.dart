import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../constants/ubicaciones_app.dart';
import '../location/ubicacion_actual.dart';

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
    final colorScheme = theme.colorScheme;

    final centroInicial = ubicacionElegida ??
        (ubicacionUsuario == null
            ? UbicacionesApp.madridMapaInicial
            : LatLng(ubicacionUsuario!.latitud, ubicacionUsuario!.longitud));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitulo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        if (gpsFallido)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.location_off, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No pudimos leer tu ubicación. Mueve el mapa y toca para fijar el punto.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
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
                              color: colorScheme.primary,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (gpsResolviendo)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
