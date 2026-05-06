import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'servicio_ubicacion_provider.dart';
import 'ubicacion_actual.dart';

/// Resuelve una unica vez la ubicacion actual y conserva el resultado.
///
/// Se invalida manualmente desde la UI cuando el usuario decide reintentar.
final ubicacionActualProvider = FutureProvider<UbicacionActual?>((ref) async {
  return ref.watch(servicioUbicacionProvider).obtenerUbicacionActual();
});
