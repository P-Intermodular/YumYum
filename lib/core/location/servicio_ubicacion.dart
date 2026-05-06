import 'ubicacion_actual.dart';

/// Contrato para resolver la ubicacion actual del dispositivo.
///
/// Devuelve `null` cuando el permiso no existe, el GPS no esta disponible o
/// la plataforma falla al resolver la posicion.
abstract class ServicioUbicacion {
  Future<UbicacionActual?> obtenerUbicacionActual();
}
