import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/ubicacion_actual_provider.dart';
import '../domain/entities/producto_model.dart';
import 'producto_repository_provider.dart';

/// Lista reactiva de productos visibles en el inicio y el mapa.
final productosProvider = FutureProvider<List<ProductoModel>>((ref) async {
  return ref.watch(productoRepositoryProvider).obtenerProductos();
});

/// Opciones discretas de radio para la busqueda por cercania.
const radiosDisponiblesKm = <double>[1, 3, 5, 10, 25, 50];

/// Radio activo para el filtrado por proximidad durante la sesion.
final radioBusquedaProvider = NotifierProvider<RadioBusquedaController, double>(
  RadioBusquedaController.new,
);

/// Gestiona el radio activo para busquedas por proximidad.
class RadioBusquedaController extends Notifier<double> {
  @override
  double build() => 10;

  void seleccionar(double radio) {
    state = radio;
  }
}

/// Lista reactiva de productos cercanos a la ubicacion actual.
///
/// Si no hay permiso o no puede resolverse el GPS, hace fallback al catalogo
/// general para no bloquear el feed ni el mapa.
final productosCercanosProvider = FutureProvider<List<ProductoModel>>(
  (ref) async {
    final ubicacion = ref.watch(ubicacionActualProvider).value;
    final repositorio = ref.watch(productoRepositoryProvider);

    if (ubicacion == null) {
      // Mientras la ubicacion se resuelve, o si falla, no bloqueamos la UI:
      // el feed y el mapa pueden mostrar el catalogo general y actualizarse
      // despues cuando llegue una posicion valida.
      return repositorio.obtenerProductos();
    }

    final radioKm = ref.watch(radioBusquedaProvider);
    return repositorio.obtenerProductosCercanos(
      latitud: ubicacion.latitud,
      longitud: ubicacion.longitud,
      radioKm: radioKm,
    );
  },
);

/// Carga el detalle de un producto concreto a partir de su identificador.
final productoDetalleProvider = FutureProvider.autoDispose
    .family<ProductoModel?, String>((ref, productoId) async {
  return ref.watch(productoRepositoryProvider).obtenerProductoPorId(productoId);
});
