import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/ubicacion_actual_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../domain/entities/producto_model.dart';
import 'producto_repository_provider.dart';

/// Bloquea la query de productos hasta que la sesión esté resuelta.
///
/// Sin esto, al arrancar la app o tras un hot-restart la sesión de Supabase
/// puede no estar todavía propagada al cliente y la RLS rechaza con 42501,
/// produciendo un flash de "No tienes permisos…" antes de que el provider
/// se re-evalúe. Devolvemos un Future que nunca resuelve mientras
/// `autenticacionProvider` esté en `loading`; al pasar a `data` Riverpod
/// cancela este future y vuelve a ejecutar el provider con sesión válida.
Future<void> _esperarSesionLista(Ref ref) {
  final estado = ref.watch(autenticacionProvider);
  if (estado.isLoading) {
    return Completer<void>().future;
  }
  return Future.value();
}

/// Lista reactiva de productos visibles en el inicio y el mapa.
final productosProvider = FutureProvider<List<ProductoModel>>((ref) async {
  await _esperarSesionLista(ref);
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
    await _esperarSesionLista(ref);

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
  await _esperarSesionLista(ref);
  return ref.watch(productoRepositoryProvider).obtenerProductoPorId(productoId);
});
