import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'servicio_ubicacion.dart';
import 'ubicacion_actual.dart';

/// Implementacion de [ServicioUbicacion] respaldada por `geolocator`.
///
/// Cualquier incidencia del dispositivo se traduce a `null` para que la app
/// pueda seguir mostrando el catalogo general como fallback.
class GeolocatorServicioUbicacion implements ServicioUbicacion {
  @override
  Future<UbicacionActual?> obtenerUbicacionActual() async {
    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) return null;

      const precision = kIsWeb ? LocationAccuracy.low : LocationAccuracy.medium;
      const timeout = kIsWeb ? Duration(seconds: 6) : Duration(seconds: 12);

      if (!kIsWeb) {
        var permiso = await Geolocator.checkPermission();
        if (permiso == LocationPermission.denied) {
          permiso = await Geolocator.requestPermission();
        }

        if (permiso == LocationPermission.denied ||
            permiso == LocationPermission.deniedForever) {
          return null;
        }
      }

      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: precision,
        timeLimit: timeout,
      );

      return UbicacionActual(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}
