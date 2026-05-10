import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../solicitudes/controllers/solicitud_oferta_controller.dart';
import '../../solicitudes/domain/entities/solicitud_oferta_model.dart';
import '../../solicitudes/providers/solicitud_oferta_providers.dart';
import '../domain/entities/transaccion_model.dart';
import '../providers/panel_pedidos_provider.dart';
import '../providers/transaccion_providers.dart';

/// Pantalla principal de pedidos. Lista en una vista única todas las
/// solicitudes y transacciones del usuario, con chips de filtro y cards
/// inspiradas en `prototipo-figma/screens-a.tsx#L467-L549`.
class PedidosScreen extends ConsumerStatefulWidget {
  const PedidosScreen({super.key});

  @override
  ConsumerState<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends ConsumerState<PedidosScreen> {
  _FiltroPedidos _filtro = _FiltroPedidos.todos;

  @override
  Widget build(BuildContext context) {
    final panelAsync = ref.watch(panelPedidosProvider);
    final usuarioId = ref.watch(autenticacionProvider).value?.id;

    return Scaffold(
      body: YumBackground(
        child: SafeArea(
          bottom: false,
          child: panelAsync.when(
            data: (panel) => _buildContenido(panel, usuarioId),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(mensajeError(e))),
          ),
        ),
      ),
    );
  }

  Widget _buildContenido(panel, String? usuarioId) {
    final items = _construirItems(panel);
    final totalPorFiltro = _contarPorFiltro(items);
    final filtrados = items.where((i) => _coincide(i, _filtro)).toList()
      ..sort((a, b) => b.fechaOrden.compareTo(a.fechaOrden));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(solicitudesRecibidasProvider);
        ref.invalidate(solicitudesEnviadasProvider);
        ref.invalidate(transaccionesListProvider);
      },
      child: Column(
        // Sin esto los paddings hijos se centran y el header queda en medio.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(enCurso: totalPorFiltro[_FiltroPedidos.enCurso] ?? 0),
          const SizedBox(height: 12),
          _BarraChips(
            seleccionado: _filtro,
            contadores: totalPorFiltro,
            onChanged: (filtro) => setState(() => _filtro = filtro),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtrados.isEmpty
                ? _MensajeVacio(
                    texto: _textoVacio(items.isEmpty),
                  )
                : _ListaPedidos(items: filtrados, usuarioId: usuarioId),
          ),
        ],
      ),
    );
  }

  /// Construye la lista de items deduplicando: si una solicitud ya tiene
  /// transacción, mostramos solo la transacción.
  List<_ItemPedido> _construirItems(panel) {
    final transacciones = panel.transacciones as List<TransaccionModel>;
    final solicitudesRecibidas =
        panel.solicitudesRecibidas as List<SolicitudOfertaModel>;
    final solicitudesEnviadas =
        panel.solicitudesEnviadas as List<SolicitudOfertaModel>;

    final idsSolicitudConTransaccion = transacciones
        .map((t) => t.solicitudId)
        .whereType<String>()
        .toSet();

    final items = <_ItemPedido>[
      for (final t in transacciones) _ItemTransaccion(t),
      for (final s in solicitudesRecibidas)
        if (!idsSolicitudConTransaccion.contains(s.id)) _ItemSolicitud(s),
      for (final s in solicitudesEnviadas)
        if (!idsSolicitudConTransaccion.contains(s.id)) _ItemSolicitud(s),
    ];
    return items;
  }

  Map<_FiltroPedidos, int> _contarPorFiltro(List<_ItemPedido> items) {
    return {
      for (final filtro in _FiltroPedidos.values)
        filtro: items.where((i) => _coincide(i, filtro)).length,
    };
  }

  bool _coincide(_ItemPedido item, _FiltroPedidos filtro) {
    return switch (filtro) {
      _FiltroPedidos.todos => true,
      _FiltroPedidos.pendientes => item.esSolicitudPendiente,
      _FiltroPedidos.enCurso => item.estaEnCurso,
      _FiltroPedidos.completados => item.estaCompletado,
    };
  }

  String _textoVacio(bool sinPedidos) {
    if (sinPedidos) return 'Todavía no tienes pedidos.';
    return switch (_filtro) {
      _FiltroPedidos.todos => 'Todavía no tienes pedidos.',
      _FiltroPedidos.pendientes => 'No tienes solicitudes pendientes.',
      _FiltroPedidos.enCurso => 'No tienes pedidos en curso.',
      _FiltroPedidos.completados => 'No tienes pedidos completados.',
    };
  }
}

enum _FiltroPedidos { todos, pendientes, enCurso, completados }

extension on _FiltroPedidos {
  String get etiqueta => switch (this) {
        _FiltroPedidos.todos => 'Todos',
        _FiltroPedidos.pendientes => 'Pendientes',
        _FiltroPedidos.enCurso => 'En curso',
        _FiltroPedidos.completados => 'Completados',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// VM unificado para la card

sealed class _ItemPedido {
  String get id;
  DateTime get fechaOrden;
  String get tituloProducto;
  String get nombreContraparte;
  String get urlImagenProducto;
  String get tipo;
  int get cantidad;

  /// Para deduplicar y para acciones inline.
  bool get esSolicitudPendiente;
  bool get estaEnCurso;
  bool get estaCompletado;
}

class _ItemSolicitud extends _ItemPedido {
  final SolicitudOfertaModel solicitud;
  _ItemSolicitud(this.solicitud);

  @override
  String get id => solicitud.id;
  @override
  DateTime get fechaOrden => solicitud.creadoEn;
  @override
  String get tituloProducto => solicitud.tituloProducto;
  @override
  String get nombreContraparte => solicitud.nombreContraparte;
  @override
  String get urlImagenProducto => solicitud.urlImagenProducto;
  @override
  String get tipo => solicitud.tipoSolicitud;
  @override
  int get cantidad => solicitud.cantidad;

  @override
  bool get esSolicitudPendiente =>
      solicitud.estado == EstadoSolicitud.pendiente;
  @override
  bool get estaEnCurso => false;
  @override
  bool get estaCompletado => false;
}

class _ItemTransaccion extends _ItemPedido {
  final TransaccionModel transaccion;
  _ItemTransaccion(this.transaccion);

  @override
  String get id => transaccion.id;
  @override
  DateTime get fechaOrden =>
      transaccion.completadoEn ?? transaccion.creadoEn;
  @override
  String get tituloProducto => transaccion.tituloProducto;
  @override
  String get nombreContraparte => transaccion.nombreContraparte;
  @override
  String get urlImagenProducto => transaccion.urlImagenProducto;
  @override
  String get tipo => transaccion.tipo;
  @override
  int get cantidad => transaccion.cantidad;

  @override
  bool get esSolicitudPendiente => false;
  @override
  bool get estaEnCurso =>
      transaccion.estado == EstadoTransaccion.pendiente ||
      transaccion.estado == EstadoTransaccion.aceptada;
  @override
  bool get estaCompletado =>
      transaccion.estado == EstadoTransaccion.completada;
}

// ─────────────────────────────────────────────────────────────────────────────
// Header

class _Header extends StatelessWidget {
  final int enCurso;

  const _Header({required this.enCurso});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final subtitulo = enCurso == 1
        ? '1 pedido en curso'
        : enCurso > 1
            ? '$enCurso pedidos en curso'
            : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis pedidos',
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitulo,
              textAlign: TextAlign.start,
              style: TextStyle(color: colors.inkSoft, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chips de filtro

class _BarraChips extends StatelessWidget {
  final _FiltroPedidos seleccionado;
  final Map<_FiltroPedidos, int> contadores;
  final ValueChanged<_FiltroPedidos> onChanged;

  const _BarraChips({
    required this.seleccionado,
    required this.contadores,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var i = 0; i < _FiltroPedidos.values.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _ChipFiltro(
              etiqueta: _construirEtiqueta(_FiltroPedidos.values[i]),
              seleccionado: seleccionado == _FiltroPedidos.values[i],
              onTap: () => onChanged(_FiltroPedidos.values[i]),
            ),
          ],
        ],
      ),
    );
  }

  String _construirEtiqueta(_FiltroPedidos filtro) {
    final cuenta = contadores[filtro] ?? 0;
    // "Todos" no muestra contador (sería redundante con la suma).
    if (filtro == _FiltroPedidos.todos || cuenta == 0) return filtro.etiqueta;
    return '${filtro.etiqueta} · $cuenta';
  }
}

class _ChipFiltro extends StatelessWidget {
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipFiltro({
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: seleccionado ? colors.ink : colors.paper,
            border: Border.all(
              color: seleccionado ? colors.ink : colors.line,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            etiqueta,
            style: TextStyle(
              color: seleccionado ? colors.paper : colors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista de cards independientes con separación vertical

class _ListaPedidos extends StatelessWidget {
  final List<_ItemPedido> items;
  final String? usuarioId;

  const _ListaPedidos({required this.items, required this.usuarioId});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) =>
          _TarjetaPedido(item: items[i], usuarioId: usuarioId),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta unificada de pedido

class _TarjetaPedido extends ConsumerWidget {
  final _ItemPedido item;
  final String? usuarioId;

  const _TarjetaPedido({required this.item, required this.usuarioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    final estado = _EstadoPedidoVisual.desde(item);
    final destino = _resolverDestino(item);

    return Material(
      color: colors.paper,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: destino == null ? null : () => context.push(destino),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CabeceraTarjeta(item: item, estado: estado),
                const SizedBox(height: 12),
                _MiniTimeline(estado: estado),
                if (_debeMostrarAcciones(item)) ...[
                  const SizedBox(height: 12),
                  _AccionesInline(item: item),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _resolverDestino(_ItemPedido item) {
    return switch (item) {
      _ItemTransaccion(:final transaccion) =>
        RutasApp.transaccionDetalle(transaccion.id),
      _ItemSolicitud(:final solicitud) =>
        RutasApp.pedidoPorSolicitud(solicitud.id),
    };
  }

  bool _debeMostrarAcciones(_ItemPedido item) =>
      item is _ItemSolicitud &&
      item.solicitud.estado == EstadoSolicitud.pendiente;
}

// ─── Cabecera (imagen + texto + pill) ─────────────────────────────────────────

class _CabeceraTarjeta extends StatelessWidget {
  final _ItemPedido item;
  final _EstadoPedidoVisual estado;

  const _CabeceraTarjeta({required this.item, required this.estado});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final precio = _precioTexto(item);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 72,
            height: 72,
            child: item.urlImagenProducto.isNotEmpty
                ? Image.network(
                    item.urlImagenProducto,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: colors.cream2),
                  )
                : Container(color: colors.cream2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.tituloProducto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (precio != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      precio,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                item.nombreContraparte,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.inkSoft,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _PillEstado(estado: estado),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      estado.eta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: estado.etaDestacado
                            ? colors.terracottaDeep
                            : colors.inkSoft,
                        fontWeight: estado.etaDestacado
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _precioTexto(_ItemPedido item) {
    if (item.tipo == TipoOferta.intercambio) return 'Trueque';
    final precio = switch (item) {
      _ItemTransaccion(:final transaccion) =>
        transaccion.total ?? transaccion.precioUnitario,
      _ItemSolicitud(:final solicitud) =>
        solicitud.precioUnitario != null
            ? solicitud.precioUnitario! * solicitud.cantidad
            : null,
    };
    if (precio == null) return null;
    return '${precio.toStringAsFixed(2)} €';
  }
}

class _PillEstado extends StatelessWidget {
  final _EstadoPedidoVisual estado;

  const _PillEstado({required this.estado});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final (bg, fg) = switch (estado.tono) {
      _TonoEstado.activo => (
          colors.terracotta.withValues(alpha: 0.18),
          colors.terracottaDeep,
        ),
      _TonoEstado.exito => (
          colors.olive.withValues(alpha: 0.18),
          colors.oliveDeep,
        ),
      _TonoEstado.neutro => (colors.cream2, colors.inkSoft),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.etiqueta,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Mini timeline horizontal de 3 pasos ─────────────────────────────────────

class _MiniTimeline extends StatelessWidget {
  final _EstadoPedidoVisual estado;

  const _MiniTimeline({required this.estado});

  static const _etiquetas = ['Reservado', 'Aceptado', 'Entregado'];

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    return Row(
      children: [
        for (var i = 0; i < _etiquetas.length; i++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: _colorPaso(i, colors),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _etiquetas[i],
                  style: TextStyle(
                    fontSize: 10,
                    color: i < estado.pasoActual
                        ? colors.ink
                        : colors.inkSoft,
                    fontWeight: i < estado.pasoActual
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (i < _etiquetas.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Color _colorPaso(int indice, YumColors colors) {
    // El paso es "activo" si indice + 1 == pasoActual, "completado" si menor.
    final completado = indice < estado.pasoActual - 1;
    final activo = indice == estado.pasoActual - 1 && !estado.esFinalizado;
    final esExito = estado.tono == _TonoEstado.exito;

    if (completado) return colors.olive;
    if (activo) return colors.terracotta;
    if (esExito && indice < estado.pasoActual) return colors.olive;
    return colors.line;
  }
}

// ─── Acciones inline (Aceptar/Denegar/Cancelar) ───────────────────────────────

class _AccionesInline extends ConsumerStatefulWidget {
  final _ItemPedido item;

  const _AccionesInline({required this.item});

  @override
  ConsumerState<_AccionesInline> createState() => _AccionesInlineState();
}

class _AccionesInlineState extends ConsumerState<_AccionesInline> {
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item is! _ItemSolicitud) return const SizedBox.shrink();
    final solicitud = item.solicitud;

    if (solicitud.esEntrante) {
      return Row(
        children: [
          Expanded(
            child: _BotonInline(
              etiqueta: 'Denegar',
              variante: _VarianteBoton.ghost,
              cargando: _cargando,
              onTap: () => _ejecutar(
                () => ref
                    .read(solicitudOfertaControllerProvider.notifier)
                    .denegar(solicitud.id),
                'Solicitud denegada',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BotonInline(
              etiqueta: 'Aceptar',
              variante: _VarianteBoton.primary,
              cargando: _cargando,
              onTap: () => _ejecutar(
                () => ref
                    .read(solicitudOfertaControllerProvider.notifier)
                    .aceptar(solicitud.id),
                'Solicitud aceptada',
              ),
            ),
          ),
        ],
      );
    }

    // Solicitud enviada pendiente: solo cancelar.
    return Align(
      alignment: Alignment.centerRight,
      child: _BotonInline(
        etiqueta: 'Cancelar solicitud',
        variante: _VarianteBoton.ghost,
        cargando: _cargando,
        onTap: () => _ejecutar(
          () => ref
              .read(solicitudOfertaControllerProvider.notifier)
              .cancelar(solicitud.id),
          'Solicitud cancelada',
        ),
      ),
    );
  }

  Future<void> _ejecutar(Future<void> Function() accion, String exito) async {
    setState(() => _cargando = true);
    try {
      await accion();
      if (!mounted) return;
      mostrarExito(context, exito);
    } catch (error) {
      if (mounted) mostrarError(context, error);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
}

enum _VarianteBoton { primary, ghost }

class _BotonInline extends StatelessWidget {
  final String etiqueta;
  final _VarianteBoton variante;
  final bool cargando;
  final VoidCallback onTap;

  const _BotonInline({
    required this.etiqueta,
    required this.variante,
    required this.cargando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final esPrimary = variante == _VarianteBoton.primary;
    final bg = esPrimary ? colors.terracotta : colors.cream2;
    final fg = esPrimary ? colors.paper : colors.terracottaDeep;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: cargando ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            cargando ? '…' : etiqueta,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Estado visual mapeado a tono / paso / pill ──────────────────────────────

enum _TonoEstado { activo, exito, neutro }

class _EstadoPedidoVisual {
  /// Paso del timeline alcanzado (1=Reservado, 2=Aceptado, 3=Entregado).
  final int pasoActual;
  final String etiqueta;
  final String eta;
  final bool etaDestacado;
  final _TonoEstado tono;

  /// El pedido ya no admite progresión natural (cancelado, denegado o
  /// entregado).
  final bool esFinalizado;

  const _EstadoPedidoVisual({
    required this.pasoActual,
    required this.etiqueta,
    required this.eta,
    this.etaDestacado = false,
    required this.tono,
    required this.esFinalizado,
  });

  static _EstadoPedidoVisual desde(_ItemPedido item) {
    return switch (item) {
      _ItemSolicitud(:final solicitud) => _desdeSolicitud(solicitud),
      _ItemTransaccion(:final transaccion) => _desdeTransaccion(transaccion),
    };
  }

  static _EstadoPedidoVisual _desdeSolicitud(SolicitudOfertaModel s) {
    final relativo = _formatearRelativo(s.creadoEn);
    switch (s.estado) {
      case EstadoSolicitud.pendiente:
        return _EstadoPedidoVisual(
          pasoActual: 1,
          etiqueta: 'Pendiente',
          eta: s.esEntrante ? 'Esperando tu respuesta' : 'Pendiente · $relativo',
          tono: _TonoEstado.activo,
          esFinalizado: false,
        );
      case EstadoSolicitud.denegada:
      case EstadoSolicitud.autoDenegada:
        return _EstadoPedidoVisual(
          pasoActual: 1,
          etiqueta: 'Denegada',
          eta: relativo,
          tono: _TonoEstado.neutro,
          esFinalizado: true,
        );
      case EstadoSolicitud.cancelada:
        return _EstadoPedidoVisual(
          pasoActual: 1,
          etiqueta: 'Cancelada',
          eta: relativo,
          tono: _TonoEstado.neutro,
          esFinalizado: true,
        );
    }
    // Si llegase un estado raro, lo mostramos neutro.
    return _EstadoPedidoVisual(
      pasoActual: 1,
      etiqueta: s.estado,
      eta: relativo,
      tono: _TonoEstado.neutro,
      esFinalizado: true,
    );
  }

  static _EstadoPedidoVisual _desdeTransaccion(TransaccionModel t) {
    final fechaCierre = t.completadoEn ?? t.creadoEn;
    final fechaTexto = _formatearRelativo(fechaCierre);

    switch (t.estado) {
      case EstadoTransaccion.aceptada:
      case EstadoTransaccion.pendiente:
        return const _EstadoPedidoVisual(
          pasoActual: 2,
          etiqueta: 'En curso',
          eta: 'Recogida pendiente',
          tono: _TonoEstado.activo,
          esFinalizado: false,
        );
      case EstadoTransaccion.completada:
        return const _EstadoPedidoVisual(
          pasoActual: 3,
          etiqueta: 'Entregado',
          eta: '¡Valora tu pedido!',
          etaDestacado: true,
          tono: _TonoEstado.exito,
          esFinalizado: true,
        );
      case EstadoTransaccion.cancelada:
        return _EstadoPedidoVisual(
          pasoActual: 2,
          etiqueta: 'Cancelada',
          eta: fechaTexto,
          tono: _TonoEstado.neutro,
          esFinalizado: true,
        );
      case EstadoTransaccion.reportada:
        return _EstadoPedidoVisual(
          pasoActual: 2,
          etiqueta: 'Reportada',
          eta: fechaTexto,
          tono: _TonoEstado.neutro,
          esFinalizado: true,
        );
    }
    return _EstadoPedidoVisual(
      pasoActual: 2,
      etiqueta: t.estado,
      eta: fechaTexto,
      tono: _TonoEstado.neutro,
      esFinalizado: true,
    );
  }

  /// Convierte una fecha en un texto relativo amable: "Hace 5 min", "Hoy",
  /// "Ayer", "Lun", "12/04".
  static String _formatearRelativo(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) return 'Hace un momento';
    if (diferencia.inMinutes < 60) return 'Hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24 && fecha.day == ahora.day) {
      return 'Hoy ${DateFormat('HH:mm').format(fecha)}';
    }
    final ayer = DateTime(ahora.year, ahora.month, ahora.day)
        .subtract(const Duration(days: 1));
    final fechaSolo = DateTime(fecha.year, fecha.month, fecha.day);
    if (fechaSolo == ayer) return 'Ayer';
    if (diferencia.inDays < 7) {
      final dia = DateFormat.E('es').format(fecha);
      return dia.isNotEmpty
          ? '${dia[0].toUpperCase()}${dia.substring(1)}'
          : dia;
    }
    return DateFormat('dd/MM').format(fecha);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado vacío

class _MensajeVacio extends StatelessWidget {
  final String texto;

  const _MensajeVacio({required this.texto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.inkSoft, fontSize: 14),
        ),
      ),
    );
  }
}
