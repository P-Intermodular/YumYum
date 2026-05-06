import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../producto/domain/entities/producto_model.dart';
import '../../producto/providers/producto_providers.dart';

/// Criterios de ordenación disponibles en el feed.
enum OrdenFeed { recientes, cercanos, valorados }

/// Texto buscado en el campo de búsqueda del feed.
final busquedaQueryProvider =
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

/// Criterio activo de ordenación. Por defecto, los más recientes.
final ordenacionFeedProvider =
    NotifierProvider<_OrdenNotifier, OrdenFeed>(_OrdenNotifier.new);

class _OrdenNotifier extends Notifier<OrdenFeed> {
  @override
  OrdenFeed build() => OrdenFeed.recientes;

  // ignore: use_setters_to_change_properties
  void set(OrdenFeed value) => state = value;
}

/// Lista final de productos visibles en el feed: aplica búsqueda + categoría +
/// etiquetas + orden sobre la lista que ya viene filtrada por radio desde
/// `productosCercanosProvider`.
final feedFiltradoProvider =
    Provider<AsyncValue<List<ProductoModel>>>((ref) {
  final productos = ref.watch(productosCercanosProvider);
  final query = _normalizar(ref.watch(busquedaQueryProvider));
  final categoria = ref.watch(categoriaSeleccionadaProvider);
  final etiquetas = ref.watch(etiquetasSeleccionadasProvider);
  final orden = ref.watch(ordenacionFeedProvider);

  return productos.whenData((lista) {
    Iterable<ProductoModel> resultado = lista;

    if (categoria != null) {
      resultado = resultado.where((p) => p.categoria == categoria);
    }

    if (etiquetas.isNotEmpty) {
      resultado = resultado.where(
        (p) => etiquetas.every((e) => p.etiquetas.contains(e)),
      );
    }

    if (query.isNotEmpty) {
      resultado = resultado.where((p) {
        final base = _normalizar('${p.titulo} ${p.descripcion}');
        return base.contains(query);
      });
    }

    final lista2 = resultado.toList();

    switch (orden) {
      case OrdenFeed.recientes:
        // El feed ya viene ordenado por creado_en desc desde la RPC.
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
  });
});

/// Cantidad de filtros activos respecto a los valores por defecto. Sirve para
/// pintar el badge en el botón de filtros.
final filtrosActivosCountProvider = Provider<int>((ref) {
  final radio = ref.watch(radioBusquedaProvider);
  final orden = ref.watch(ordenacionFeedProvider);
  final etiquetas = ref.watch(etiquetasSeleccionadasProvider);

  var count = 0;
  if (radio != 10) count += 1;
  if (orden != OrdenFeed.recientes) count += 1;
  if (etiquetas.isNotEmpty) count += 1;
  return count;
});

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
