import 'package:latlong2/latlong.dart';

/// Coordenadas de referencia usadas en el MVP cuando no hay geolocalización real.
abstract final class UbicacionesApp {
  static const madridCentro = LatLng(40.4180, -3.7050);
  static const madridMapaInicial = LatLng(40.4168, -3.7038);
}
