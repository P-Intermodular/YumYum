import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/ubicacion_actual_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../inicio/providers/feed_filtros_providers.dart';
import '../../producto/domain/entities/producto_model.dart';
import '../../producto/providers/producto_repository_provider.dart';

/// Bloquea la query mientras la sesion no este resuelta para evitar el
/// flash de "sin permisos" antes de que llegue el JWT.
Future<void> _esperarSesionLista(Ref ref) {
  final estado = ref.watch(autenticacionProvider);
  if (estado.isLoading) {
    return Completer<void>().future;
  }
  return Future.value();
}

/// Radio que la RPC trata como "sin filtro real": cubre cualquier distancia
/// continental conservando el calculo de distancia.
const _radioSinLimiteKm = 999.0;
const _limiteSinLimite = 200;

final radioZonaVisibleMapaProvider =
    NotifierProvider<RadioZonaVisibleMapaNotifier, double>(
  RadioZonaVisibleMapaNotifier.new,
);

class RadioZonaVisibleMapaNotifier extends Notifier<double> {
  @override
  double build() => 10;

  void establecer(double radioKm) => state = radioKm;
}

/// Centro de busqueda activo para la pantalla de mapa.
///
/// `null` significa "usa la ubicacion GPS del usuario". Cuando el usuario
/// pulsa el FAB **Buscar aqui**, este provider se actualiza con el centro
/// del viewport del mapa, permitiendo explorar otras zonas sin afectar al
/// feed de inicio (que sigue anclado al GPS via `productosCercanosProvider`).
///
/// Esta separacion es deliberada: el mapa es exploratorio, el feed
/// representa "cerca de ti" y debe permanecer estable para el usuario.
final centroMapaProvider =
    NotifierProvider<CentroMapaNotifier, LatLng?>(CentroMapaNotifier.new);

class CentroMapaNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;

  // ignore: use_setters_to_change_properties
  void establecer(LatLng? centro) => state = centro;

  void limpiar() => state = null;
}

/// Lista de productos para la pantalla de mapa.
///
/// Identico a `productosCercanosProvider` pero usando como centro
/// `centroMapaProvider ?? gps`. Si ni override ni GPS estan disponibles
/// se devuelve el catalogo completo para no dejar el mapa vacio.
final productosMapaProvider = FutureProvider<List<ProductoModel>>(
  (ref) async {
    await _esperarSesionLista(ref);

    final repositorio = ref.watch(productoRepositoryProvider);
    final ubicacionGps = ref.watch(ubicacionActualProvider).value;
    final centroOverride = ref.watch(centroMapaProvider);

    final centro = centroOverride ??
        (ubicacionGps == null
            ? null
            : LatLng(ubicacionGps.latitud, ubicacionGps.longitud));

    if (centro == null) {
      return repositorio.obtenerProductos();
    }

    final distancia = ref.watch(mapaDistanciaProvider);
    final radioZonaVisibleKm = ref.watch(radioZonaVisibleMapaProvider);
    final radioKm = switch (distancia.modo) {
      ModoDistanciaMapa.zonaVisible => radioZonaVisibleKm,
      ModoDistanciaMapa.radio => distancia.radioKm ?? radioZonaVisibleKm,
      ModoDistanciaMapa.todas => _radioSinLimiteKm,
    };

    return repositorio.obtenerProductosCercanos(
      latitud: centro.latitude,
      longitud: centro.longitude,
      radioKm: radioKm,
      limite: distancia.modo == ModoDistanciaMapa.todas ? _limiteSinLimite : 50,
    );
  },
);

/// Productos visibles en el mapa tras aplicar los filtros compartidos con el
/// feed (busqueda, categoria, etiquetas, alergenos, tipo, orden).
final feedMapaFiltradoProvider =
    Provider<AsyncValue<List<ProductoModel>>>((ref) {
  final productos = ref.watch(productosMapaProvider);
  return productos.whenData(
    (lista) => aplicarFiltrosFeed(
      lista,
      query: ref.watch(mapaBusquedaQueryProvider),
      categoria: ref.watch(mapaCategoriaSeleccionadaProvider),
      etiquetas: ref.watch(mapaEtiquetasSeleccionadasProvider),
      alergenosExcluidos: ref.watch(mapaAlergenosExcluidosProvider),
      tipoOferta: ref.watch(mapaTipoOfertaFiltroProvider),
      orden: ref.watch(mapaOrdenacionFeedProvider),
    ),
  );
});
