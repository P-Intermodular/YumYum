import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/alergenos_ue.dart';
import '../../../core/constants/estados_app.dart';
import '../../../core/constants/etiquetas_dieteticas.dart';
import '../../../core/theme/yum_colors.dart';
import '../../producto/domain/entities/producto_model.dart';
import '../../producto/providers/producto_providers.dart';
import '../providers/feed_filtros_providers.dart';

/// Abre el bottom sheet de filtros del feed (distancia + ordenación).
Future<void> mostrarFiltrosFeed(
  BuildContext context, {
  FiltrosProductosScope scope = FiltrosProductosScope.inicio,
  Provider<AsyncValue<List<ProductoModel>>>? resultadosProvider,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => _FiltrosFeedSheet(
      scope: scope,
      resultadosProvider: resultadosProvider,
    ),
  );
}

class _FiltrosFeedSheet extends ConsumerWidget {
  final FiltrosProductosScope scope;
  final Provider<AsyncValue<List<ProductoModel>>>? resultadosProvider;

  const _FiltrosFeedSheet({
    required this.scope,
    required this.resultadosProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    final radioActivo = scope == FiltrosProductosScope.inicio
        ? ref.watch(radioBusquedaProvider)
        : ref.watch(mapaRadioBusquedaProvider);
    final ordenActiva = scope == FiltrosProductosScope.inicio
        ? ref.watch(ordenacionFeedProvider)
        : ref.watch(mapaOrdenacionFeedProvider);
    final total =
        ref.watch(resultadosProvider ?? feedFiltradoProvider).maybeWhen(
              data: (lista) => lista.length,
              orElse: () => 0,
            );

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.line),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtros',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.ink,
                              ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _resetFiltros(ref),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        'Restablecer',
                        style: TextStyle(
                          color: colors.terracottaDeep,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _Subtitulo(texto: 'Distancia máxima'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final radio in radiosDisponiblesKm)
                    _Pill(
                      label: radio == null ? 'Todas' : '${radio.toInt()} km',
                      activa: radio == radioActivo,
                      onTap: () => _seleccionarRadio(ref, radio),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const _Subtitulo(texto: 'Restricciones dietéticas'),
              const SizedBox(height: 10),
              Consumer(
                builder: (context, ref, _) {
                  final activas = scope == FiltrosProductosScope.inicio
                      ? ref.watch(etiquetasSeleccionadasProvider)
                      : ref.watch(mapaEtiquetasSeleccionadasProvider);
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final etq in EtiquetasDieteticas.todas)
                        _Pill(
                          label: etq,
                          activa: activas.contains(etq),
                          onTap: () => _toggleEtiqueta(ref, etq),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const _Subtitulo(texto: 'Tipo de oferta'),
              const SizedBox(height: 10),
              Consumer(
                builder: (context, ref, _) {
                  final tipo = scope == FiltrosProductosScope.inicio
                      ? ref.watch(tipoOfertaFiltroProvider)
                      : ref.watch(mapaTipoOfertaFiltroProvider);
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        label: 'Todo',
                        activa: tipo == null,
                        onTap: () => _setTipoOferta(ref, null),
                      ),
                      _Pill(
                        label: 'Intercambio',
                        activa: tipo == TipoOferta.intercambio,
                        onTap: () =>
                            _setTipoOferta(ref, TipoOferta.intercambio),
                      ),
                      _Pill(
                        label: 'Venta',
                        activa: tipo == TipoOferta.venta,
                        onTap: () => _setTipoOferta(ref, TipoOferta.venta),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const _Subtitulo(texto: 'Excluir alérgenos'),
              const SizedBox(height: 4),
              Text(
                'Marca lo que quieras evitar.',
                style: TextStyle(
                  color: colors.inkSoft,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Consumer(
                builder: (context, ref, _) {
                  final excluidos = scope == FiltrosProductosScope.inicio
                      ? ref.watch(alergenosExcluidosProvider)
                      : ref.watch(mapaAlergenosExcluidosProvider);
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in AlergenosUe.todos)
                        _Pill(
                          label: a,
                          activa: excluidos.contains(a),
                          onTap: () => _toggleAlergeno(ref, a),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const _Subtitulo(texto: 'Ordenar por'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    label: 'Recientes',
                    activa: ordenActiva == OrdenFeed.recientes,
                    onTap: () => _setOrden(ref, OrdenFeed.recientes),
                  ),
                  _Pill(
                    label: 'Más cercanos',
                    activa: ordenActiva == OrdenFeed.cercanos,
                    onTap: () => _setOrden(ref, OrdenFeed.cercanos),
                  ),
                  _Pill(
                    label: 'Mejor valorados',
                    activa: ordenActiva == OrdenFeed.valorados,
                    onTap: () => _setOrden(ref, OrdenFeed.valorados),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.terracotta,
                    foregroundColor: colors.paper,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Ver $total ${total == 1 ? 'oferta' : 'ofertas'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetFiltros(WidgetRef ref) {
    if (scope == FiltrosProductosScope.inicio) {
      ref.read(radioBusquedaProvider.notifier).seleccionar(null);
      ref.read(ordenacionFeedProvider.notifier).set(OrdenFeed.recientes);
      ref.read(etiquetasSeleccionadasProvider.notifier).limpiar();
      ref.read(alergenosExcluidosProvider.notifier).limpiar();
      ref.read(tipoOfertaFiltroProvider.notifier).set(null);
    } else {
      ref.read(mapaRadioBusquedaProvider.notifier).seleccionar(null);
      ref.read(mapaOrdenacionFeedProvider.notifier).set(OrdenFeed.recientes);
      ref.read(mapaEtiquetasSeleccionadasProvider.notifier).limpiar();
      ref.read(mapaAlergenosExcluidosProvider.notifier).limpiar();
      ref.read(mapaTipoOfertaFiltroProvider.notifier).set(null);
    }
  }

  void _seleccionarRadio(WidgetRef ref, double? radio) {
    if (scope == FiltrosProductosScope.inicio) {
      ref.read(radioBusquedaProvider.notifier).seleccionar(radio);
    } else {
      ref.read(mapaRadioBusquedaProvider.notifier).seleccionar(radio);
    }
  }

  void _toggleEtiqueta(WidgetRef ref, String etiqueta) {
    if (scope == FiltrosProductosScope.inicio) {
      ref.read(etiquetasSeleccionadasProvider.notifier).toggle(etiqueta);
    } else {
      ref.read(mapaEtiquetasSeleccionadasProvider.notifier).toggle(etiqueta);
    }
  }

  void _setTipoOferta(WidgetRef ref, String? tipo) {
    if (scope == FiltrosProductosScope.inicio) {
      ref.read(tipoOfertaFiltroProvider.notifier).set(tipo);
    } else {
      ref.read(mapaTipoOfertaFiltroProvider.notifier).set(tipo);
    }
  }

  void _toggleAlergeno(WidgetRef ref, String alergeno) {
    if (scope == FiltrosProductosScope.inicio) {
      ref.read(alergenosExcluidosProvider.notifier).toggle(alergeno);
    } else {
      ref.read(mapaAlergenosExcluidosProvider.notifier).toggle(alergeno);
    }
  }

  void _setOrden(WidgetRef ref, OrdenFeed orden) {
    if (scope == FiltrosProductosScope.inicio) {
      ref.read(ordenacionFeedProvider.notifier).set(orden);
    } else {
      ref.read(mapaOrdenacionFeedProvider.notifier).set(orden);
    }
  }
}

class _Subtitulo extends StatelessWidget {
  final String texto;
  const _Subtitulo({required this.texto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        color: colors.inkSoft,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool activa;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.activa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activa ? colors.terracotta : colors.cream2,
          border: Border.all(
            color: activa ? colors.terracotta : colors.line,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: activa ? colors.paper : colors.ink,
            fontSize: 13,
            fontWeight: activa ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
