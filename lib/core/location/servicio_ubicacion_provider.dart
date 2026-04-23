import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'geolocator_servicio_ubicacion.dart';
import 'servicio_ubicacion.dart';

/// Punto de inyeccion para la estrategia de geolocalizacion de la app.
final servicioUbicacionProvider = Provider<ServicioUbicacion>((ref) {
  return GeolocatorServicioUbicacion();
});
