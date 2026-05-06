import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../producto/domain/entities/producto_model.dart';
import '../../producto/providers/producto_providers.dart';

/// Criterios de ordenación disponibles en el feed.
enum OrdenFeed { recientes, cercanos, valorados }

enum FiltrosProductosScope { inicio, mapa }

/// Texto buscado en el campo de búsqueda del feed.
final busquedaQueryProvider =
    NotifierProvider<_StringNotifier, String>(_StringNotifier.new);
final mapaBusquedaQueryProvider =
    NotifierProvider<_StringNotifier, String>(_StringNotifier.new);

class _StringNotifier extends Notifier<String> {
  @override
  String build() => '';

  // ignore: use_setters_to_change_properties
  void set(String value) => state = value;
}

/// Categoría visualmente seleccionada en las chips. `null` = "Todo".
final categoriaSeleccionadaProvider =
    NotifierProvider<_CategoriaNotifier, String?>(_CategoriaNotifier.new);
final mapaCategoriaSeleccionadaProvider =
    NotifierProvider<_CategoriaNotifier, String?>(_CategoriaNotifier.new);

class _CategoriaNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  // ignore: use_setters_to_change_properties
  void set(String? value) => state = value;
}

/// Etiquetas dietéticas activas como filtro multi-select. Si está vacío no
/// aplica ningún filtro de etiquetas.
final etiquetasSeleccionadasProvider =
    NotifierProvider<_EtiquetasNotifier, Set<String>>(_EtiquetasNotifier.new);
final mapaEtiquetasSeleccionadasProvider =
    NotifierProvider<_EtiquetasNotifier, Set<String>>(_EtiquetasNotifier.new);

class _EtiquetasNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void toggle(String valor) {
    final actual = {...state};
    if (actual.contains(valor)) {
      actual.remove(valor);
    } else {
      actual.add(valor);
    }
    state = actual;
  }

  void limpiar() => state = const <String>{};
}

/// Alérgenos del Anexo II que el usuario quiere **excluir** de los resultados.
///
/// Política conservadora (OR): se descarta cualquier plato cuya lista
/// `alergenos` contenga al menos uno de los marcados aquí. Los platos que
/// declaran `sin_alergenos_declarados=true` se consideran seguros y siempre
/// pasan el filtro.
final alergenosExcluidosProvider =
    NotifierProvider<_AlergenosNotifier, Set<String>>(_AlergenosNotifier.new);
final mapaAlergenosExcluidosProvider =
    NotifierProvider<_AlergenosNotifier, Set<String>>(_AlergenosNotifier.new);

class _AlergenosNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void toggle(String valor) {
    final actual = {...state};
    if (actual.contains(valor)) {
      actual.remove(valor);
    } else {
      actual.add(valor);
    }
    state = actual;
  }

  void limpiar() => state = const <String>{};
}

/// Filtro por tipo de oferta. `null` = todos, en otro caso `'venta'` o
/// `'intercambio'`.
final tipoOfertaFiltroProvider =
    NotifierProvider<_TipoOfertaNotifier, String?>(_TipoOfertaNotifier.new);
final mapaTipoOfertaFiltroProvider =
    NotifierProvider<_TipoOfertaNotifier, String?>(_TipoOfertaNotifier.new);

class _TipoOfertaNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  // ignore: use_setters_to_change_properties
  void set(String? value) => state = value;
}

/// Criterio activo de ordenación. Por defecto, los más recientes.
final ordenacionFeedProvider =
    NotifierProvider<_OrdenNotifier, OrdenFeed>(_OrdenNotifier.new);
final mapaOrdenacionFeedProvider =
    NotifierProvider<_OrdenNotifier, OrdenFeed>(_OrdenNotifier.new);

class _OrdenNotifier extends Notifier<OrdenFeed> {
  @override
  OrdenFeed build() => OrdenFeed.recientes;

  // ignore: use_setters_to_change_properties
  void set(OrdenFeed value) => state = value;
}

final mapaRadioBusquedaProvider =
    NotifierProvider<RadioBusquedaController, double?>(
  RadioBusquedaController.new,
);

/// Aplica el pipeline completo de filtros del feed (búsqueda, categoría,
/// etiquetas, alérgenos excluidos, tipo de oferta y orden) sobre una lista
/// concreta de productos.
///
/// Se expone como función pura para que pantallas distintas (feed inicio,
/// mapa) puedan compartir exactamente el mismo comportamiento sobre listas
/// con orígenes distintos (`productosCercanosProvider`,
/// `productosMapaProvider`, etc.).
List<ProductoModel> aplicarFiltrosFeed(
  List<ProductoModel> lista, {
  required String query,
  required String? categoria,
  required Set<String> etiquetas,
  required Set<String> alergenosExcluidos,
  required String? tipoOferta,
  required OrdenFeed orden,
}) {
  final queryNormalizada = _normalizar(query);
  Iterable<ProductoModel> resultado = lista;

  if (categoria != null) {
    resultado = resultado.where((p) => p.categoria == categoria);
  }

  if (tipoOferta != null) {
    resultado = resultado.where((p) => p.tipo == tipoOferta);
  }

  if (etiquetas.isNotEmpty) {
    resultado = resultado.where(
      (p) => etiquetas.every((e) => p.etiquetas.contains(e)),
    );
  }

  if (alergenosExcluidos.isNotEmpty) {
    // Política OR: se excluye el plato si CONTIENE alguno de los marcados.
    // Si el cocinero declaró "sin alérgenos del Anexo II" se considera
    // seguro y se mantiene visible.
    resultado = resultado.where((p) {
      if (p.sinAlergenosDeclarados) return true;
      return !p.alergenos.any(alergenosExcluidos.contains);
    });
  }

  if (queryNormalizada.isNotEmpty) {
    resultado = resultado.where((p) {
      final base = _normalizar('${p.titulo} ${p.descripcion}');
      return base.contains(queryNormalizada);
    });
  }

  final lista2 = resultado.toList();

  switch (orden) {
    case OrdenFeed.recientes:
      // La lista ya viene ordenada por creado_en desc desde la RPC.
      break;
    case OrdenFeed.cercanos:
      lista2.sort((a, b) {
        final da = a.distanciaKm ?? double.infinity;
        final db = b.distanciaKm ?? double.infinity;
        return da.compareTo(db);
      });
      break;
    case OrdenFeed.valorados:
      lista2.sort(
        (a, b) => b.propietario.valoracionMedia
            .compareTo(a.propietario.valoracionMedia),
      );
      break;
  }

  return lista2;
}

/// Lista final de productos visibles en el feed: aplica búsqueda + categoría +
/// etiquetas + orden sobre la lista que ya viene filtrada por radio desde
/// `productosCercanosProvider`.
final feedFiltradoProvider = Provider<AsyncValue<List<ProductoModel>>>((ref) {
  final productos = ref.watch(productosCercanosProvider);
  return productos.whenData(
    (lista) => aplicarFiltrosFeed(
      lista,
      query: ref.watch(busquedaQueryProvider),
      categoria: ref.watch(categoriaSeleccionadaProvider),
      etiquetas: ref.watch(etiquetasSeleccionadasProvider),
      alergenosExcluidos: ref.watch(alergenosExcluidosProvider),
      tipoOferta: ref.watch(tipoOfertaFiltroProvider),
      orden: ref.watch(ordenacionFeedProvider),
    ),
  );
});

/// Cantidad de filtros activos respecto a los valores por defecto. Sirve para
/// pintar el badge en el botón de filtros.
final filtrosActivosCountProvider = Provider<int>((ref) {
  return contarFiltrosActivos(
    radio: ref.watch(radioBusquedaProvider),
    orden: ref.watch(ordenacionFeedProvider),
    etiquetas: ref.watch(etiquetasSeleccionadasProvider),
    alergenosExcluidos: ref.watch(alergenosExcluidosProvider),
    tipoOferta: ref.watch(tipoOfertaFiltroProvider),
  );
});

final filtrosMapaActivosCountProvider = Provider<int>((ref) {
  return contarFiltrosActivos(
    radio: ref.watch(mapaRadioBusquedaProvider),
    orden: ref.watch(mapaOrdenacionFeedProvider),
    etiquetas: ref.watch(mapaEtiquetasSeleccionadasProvider),
    alergenosExcluidos: ref.watch(mapaAlergenosExcluidosProvider),
    tipoOferta: ref.watch(mapaTipoOfertaFiltroProvider),
  );
});

int contarFiltrosActivos({
  required double? radio,
  required OrdenFeed orden,
  required Set<String> etiquetas,
  required Set<String> alergenosExcluidos,
  required String? tipoOferta,
}) {
  var count = 0;
  // El default es "Todas" (null). Cualquier radio concreto cuenta como filtro.
  if (radio != null) count += 1;
  if (orden != OrdenFeed.recientes) count += 1;
  if (etiquetas.isNotEmpty) count += 1;
  if (alergenosExcluidos.isNotEmpty) count += 1;
  if (tipoOferta != null) count += 1;
  return count;
}

String _normalizar(String texto) {
  // Acentos a-z básicos: pasamos a minúsculas y quitamos diacríticos comunes.
  final lower = texto.toLowerCase().trim();
  const reemplazos = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  var resultado = lower;
  reemplazos.forEach((acento, plano) {
    resultado = resultado.replaceAll(acento, plano);
  });
  return resultado;
}
