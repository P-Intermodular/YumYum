import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../producto/providers/ubicacion_exacta_provider.dart';
import '../../solicitudes/controllers/solicitud_oferta_controller.dart';
import '../../valoraciones/providers/valoracion_providers.dart';
import '../controllers/transaccion_controller.dart';
import '../domain/entities/pedido_unificado_model.dart';
import '../providers/pedido_unificado_provider.dart';

/// Pantalla de detalle de un pedido (solicitud + transacción) accesible desde
/// el chat o desde la lista de pedidos.
///
/// Acepta un [PedidoRef] para que el mismo widget cubra el caso "solicitud
/// pendiente sin transacción" y el caso "transacción ya aceptada", siguiendo
/// el prototipo `prototipo-figma/src/app/components/yum/screens-b.tsx#L5-L82`.
class DetalleTransaccionScreen extends ConsumerStatefulWidget {
  final PedidoRef pedido;

  const DetalleTransaccionScreen({super.key, required this.pedido});

  /// Atajo para construir la pantalla a partir del id de transacción
  /// (ruta legacy `/transaccion/:id`).
  factory DetalleTransaccionScreen.porTransaccion(String transaccionId) {
    return DetalleTransaccionScreen(
      pedido: PedidoRef.porTransaccion(transaccionId),
    );
  }

  /// Atajo para construir la pantalla a partir del id de solicitud
  /// (ruta `/pedido/solicitud/:id`, usada cuando aún no hay transacción).
  factory DetalleTransaccionScreen.porSolicitud(String solicitudId) {
    return DetalleTransaccionScreen(
      pedido: PedidoRef.porSolicitud(solicitudId),
    );
  }

  @override
  ConsumerState<DetalleTransaccionScreen> createState() =>
      _DetalleTransaccionScreenState();
}

class _DetalleTransaccionScreenState
    extends ConsumerState<DetalleTransaccionScreen> {
  Future<void> _aceptarSolicitud(String solicitudId) async {
    try {
      await ref
          .read(solicitudOfertaControllerProvider.notifier)
          .aceptar(solicitudId);
      if (!mounted) return;
      mostrarExito(context, 'Solicitud aceptada');
    } catch (error) {
      if (mounted) mostrarError(context, error);
    }
  }

  Future<void> _denegarSolicitud(String solicitudId) async {
    final confirmado = await _confirmar(
      titulo: 'Denegar solicitud',
      contenido:
          '¿Seguro que quieres denegar esta solicitud? El producto seguirá disponible para otros vecinos.',
      textoConfirmar: 'Denegar',
    );
    if (confirmado != true || !mounted) return;

    try {
      await ref
          .read(solicitudOfertaControllerProvider.notifier)
          .denegar(solicitudId);
      if (!mounted) return;
      mostrarExito(context, 'Solicitud denegada');
    } catch (error) {
      if (mounted) mostrarError(context, error);
    }
  }

  Future<void> _cancelarSolicitud(String solicitudId) async {
    final confirmado = await _confirmar(
      titulo: 'Cancelar solicitud',
      contenido:
          '¿Seguro que quieres retirar tu solicitud? Podrás volver a contactar al cocinero más tarde.',
      textoConfirmar: 'Cancelar solicitud',
    );
    if (confirmado != true || !mounted) return;

    try {
      await ref
          .read(solicitudOfertaControllerProvider.notifier)
          .cancelar(solicitudId);
      if (!mounted) return;
      mostrarExito(context, 'Solicitud cancelada');
    } catch (error) {
      if (mounted) mostrarError(context, error);
    }
  }

  Future<void> _completarTransaccion(String transaccionId) async {
    try {
      await ref
          .read(transaccionControllerProvider.notifier)
          .completar(transaccionId);
      if (!mounted) return;
      mostrarExito(context, 'Pedido marcado como entregado');
      context.push(RutasApp.valorarTransaccion(transaccionId));
    } catch (error) {
      if (mounted) mostrarError(context, error);
    }
  }

  Future<void> _cancelarTransaccion(String transaccionId) async {
    final confirmado = await _confirmar(
      titulo: 'Cancelar transacción',
      contenido:
          '¿Seguro que quieres cancelar esta transacción? Los productos volverán a estar disponibles.',
      textoConfirmar: 'Cancelar transacción',
    );
    if (confirmado != true || !mounted) return;

    try {
      await ref
          .read(transaccionControllerProvider.notifier)
          .cancelar(transaccionId);
      if (!mounted) return;
      mostrarExito(context, 'Transacción cancelada');
    } catch (error) {
      if (mounted) mostrarError(context, error);
    }
  }

  Future<bool?> _confirmar({
    required String titulo,
    required String contenido,
    required String textoConfirmar,
  }) {
    final colors = Theme.of(context).extension<YumColors>()!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.line),
        ),
        title: Text(
          titulo,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                color: colors.ink,
              ),
        ),
        content: Text(
          contenido,
          style: TextStyle(color: colors.inkSoft, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: colors.inkSoft),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: colors.terracottaDeep),
            child: Text(textoConfirmar),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedidoAsync = ref.watch(pedidoUnificadoProvider(widget.pedido));
    final usuario = ref.watch(autenticacionProvider).value;
    final cargandoTransaccion =
        ref.watch(transaccionControllerProvider).isLoading;
    final cargandoSolicitud =
        ref.watch(solicitudOfertaControllerProvider).isLoading;
    final cargando = cargandoTransaccion || cargandoSolicitud;

    return Scaffold(
      appBar: const YumYumAppBar(
        titulo: 'Pedido',
        mostrarBotonVolver: true,
        mostrarBotonPerfil: false,
      ),
      body: YumBackground(
        child: pedidoAsync.when(
          data: (pedido) {
            if (pedido == null || usuario == null) {
              return _buildMensajeCentrado('Pedido no encontrado');
            }
            return _buildContenido(pedido, usuario.id, cargando);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildMensajeCentrado(mensajeError(e)),
        ),
      ),
    );
  }

  Widget _buildMensajeCentrado(String texto) {
    final colors = context.yumColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.inkSoft),
        ),
      ),
    );
  }

  Widget _buildContenido(
    PedidoUnificadoModel pedido,
    String usuarioId,
    bool cargando,
  ) {
    final esSolicitante = pedido.esSolicitante(usuarioId);
    final estadoVisual = _EstadoPedidoVisual.desde(pedido);

    final yaValoroAsync = pedido.transaccionId == null
        ? const AsyncValue<dynamic>.data(null)
        : ref.watch(
            valoracionUsuarioProvider((pedido.transaccionId!, usuarioId)),
          );
    final yaValoro = yaValoroAsync.value != null;

    return Stack(
      children: [
        SingleChildScrollView(
          // Hueco para el footer sticky.
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CabeceraPedido(pedido: pedido),
              const SizedBox(height: 16),
              _TarjetaPlato(pedido: pedido, estado: estadoVisual),
              const SizedBox(height: 16),
              _TimelinePedido(estado: estadoVisual, pedido: pedido),
              const SizedBox(height: 16),
              if (estadoVisual.mostrarMapa) ...[
                _BloqueRecogida(productoId: pedido.productoId),
                const SizedBox(height: 16),
              ],
              if (pedido.tipo == TipoOferta.venta) ...[
                _DesglosePrecio(pedido: pedido),
                const SizedBox(height: 16),
              ],
              if (estadoVisual.esFinalizado)
                _BadgeEstadoFinal(estado: estadoVisual, yaValoro: yaValoro),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _FooterAcciones(
            pedido: pedido,
            esSolicitante: esSolicitante,
            estado: estadoVisual,
            cargando: cargando,
            yaValoro: yaValoro,
            onAceptar: () => _aceptarSolicitud(pedido.solicitudId),
            onDenegar: () => _denegarSolicitud(pedido.solicitudId),
            onCancelarSolicitud: () => _cancelarSolicitud(pedido.solicitudId),
            onCompletar: pedido.transaccionId == null
                ? null
                : () => _completarTransaccion(pedido.transaccionId!),
            onCancelarTransaccion: pedido.transaccionId == null
                ? null
                : () => _cancelarTransaccion(pedido.transaccionId!),
            onAbrirChat: pedido.conversacionId == null
                ? null
                : () => context.push(RutasApp.chat(pedido.conversacionId!)),
            onValorar: pedido.transaccionId == null
                ? null
                : () => context
                    .push(RutasApp.valorarTransaccion(pedido.transaccionId!)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cabecera con código del pedido y subtítulo (fecha)

class _CabeceraPedido extends StatelessWidget {
  final PedidoUnificadoModel pedido;

  const _CabeceraPedido({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final fecha = DateFormat('dd MMM · HH:mm').format(pedido.creadoEn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pedido #${pedido.codigoCorto}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                color: colors.ink,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          fecha,
          style: TextStyle(color: colors.inkSoft, fontSize: 13),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta superior con imagen del plato + título + badge de estado

class _TarjetaPlato extends StatelessWidget {
  final PedidoUnificadoModel pedido;
  final _EstadoPedidoVisual estado;

  const _TarjetaPlato({required this.pedido, required this.estado});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: pedido.urlImagenProducto.isNotEmpty
                ? Image.network(
                    pedido.urlImagenProducto,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: colors.cream2),
                  )
                : Container(color: colors.cream2),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pedido.tituloProducto,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 17,
                              color: colors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _BadgeEstado(estado: estado),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${pedido.cantidad} ${pedido.cantidad == 1 ? 'ración' : 'raciones'} · ${pedido.nombreContraparte}',
                  style: TextStyle(color: colors.inkSoft, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeEstado extends StatelessWidget {
  final _EstadoPedidoVisual estado;

  const _BadgeEstado({required this.estado});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.etiqueta,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline 3 pasos: Reservado → Aceptado → Entregado

class _TimelinePedido extends StatelessWidget {
  final _EstadoPedidoVisual estado;
  final PedidoUnificadoModel pedido;

  const _TimelinePedido({required this.estado, required this.pedido});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    final pasos = <_PasoTimeline>[
      _PasoTimeline(
        titulo: 'Reservado',
        subtitulo: DateFormat('HH:mm').format(pedido.creadoEn),
        completado: estado.pasoActual >= 1,
        activo: estado.pasoActual == 1 && !estado.esFinalizado,
      ),
      _PasoTimeline(
        titulo: 'Aceptado por ${pedido.nombreContraparte.split(' ').first}',
        subtitulo: pedido.aceptadoEn != null
            ? DateFormat('HH:mm').format(pedido.aceptadoEn!)
            : 'esperando al cocinero',
        completado: estado.pasoActual >= 2,
        activo: estado.pasoActual == 2 && !estado.esFinalizado,
      ),
      _PasoTimeline(
        titulo: 'Entregado',
        subtitulo: pedido.completadoEn != null
            ? DateFormat('HH:mm').format(pedido.completadoEn!)
            : '—',
        completado: estado.pasoActual >= 3,
        activo: estado.pasoActual == 3 && !estado.esFinalizado,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESTADO DEL PEDIDO',
            style: TextStyle(
              fontSize: 11,
              color: colors.inkSoft,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < pasos.length; i++)
            _FilaPasoTimeline(
              paso: pasos[i],
              esUltimo: i == pasos.length - 1,
            ),
        ],
      ),
    );
  }
}

class _PasoTimeline {
  final String titulo;
  final String subtitulo;
  final bool completado;
  final bool activo;

  const _PasoTimeline({
    required this.titulo,
    required this.subtitulo,
    required this.completado,
    required this.activo,
  });
}

class _FilaPasoTimeline extends StatelessWidget {
  final _PasoTimeline paso;
  final bool esUltimo;

  const _FilaPasoTimeline({required this.paso, required this.esUltimo});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    final (colorCirculo, colorIcono) = paso.activo
        ? (colors.terracotta, colors.paper)
        : paso.completado
            ? (colors.olive, colors.paper)
            : (colors.cream2, colors.inkSoft);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorCirculo,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  paso.completado
                      ? Icons.check_rounded
                      : Icons.circle_rounded,
                  size: paso.completado ? 16 : 8,
                  color: colorIcono,
                ),
              ),
              if (!esUltimo)
                Expanded(
                  child: Container(
                    width: 1,
                    color: paso.completado
                        ? colors.olive.withValues(alpha: 0.6)
                        : colors.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: esUltimo ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paso.titulo,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    paso.subtitulo,
                    style: TextStyle(fontSize: 12, color: colors.inkSoft),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bloque de recogida con mapa

class _BloqueRecogida extends ConsumerWidget {
  final String productoId;

  const _BloqueRecogida({required this.productoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    final ubicacionAsync = ref.watch(ubicacionExactaProvider(productoId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.olive.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.location_on_outlined,
                    color: colors.oliveDeep, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Recogida',
                style: TextStyle(
                  fontSize: 15,
                  color: colors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ubicacionAsync.when(
            data: (latLng) => latLng == null
                ? Text(
                    'Lugar de recogida no disponible aún.',
                    style: TextStyle(color: colors.inkSoft, fontSize: 13),
                  )
                : _MiniMapaRecogida(punto: latLng),
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Text(
              'Lugar de recogida no disponible aún.',
              style: TextStyle(color: colors.inkSoft, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMapaRecogida extends StatelessWidget {
  final LatLng punto;

  const _MiniMapaRecogida({required this.punto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 160,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: punto,
            initialZoom: 16,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.yumyum.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: punto,
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.location_on,
                    color: colors.terracotta,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desglose simple del precio (subtotal por unidad y total)

class _DesglosePrecio extends StatelessWidget {
  final PedidoUnificadoModel pedido;

  const _DesglosePrecio({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    final precioUnitario = pedido.precioUnitario;
    final total = pedido.total ??
        (precioUnitario != null ? precioUnitario * pedido.cantidad : null);
    final textoSubtotal = precioUnitario == null
        ? '—'
        : '${(precioUnitario * pedido.cantidad).toStringAsFixed(2)} €';
    final textoTotal = total == null ? '—' : '${total.toStringAsFixed(2)} €';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _FilaDesglose(
            etiqueta: '${pedido.cantidad} × ${pedido.tituloProducto}',
            valor: textoSubtotal,
          ),
          Divider(color: colors.line, height: 24, thickness: 1),
          _FilaDesglose(
            etiqueta: 'Total',
            valor: textoTotal,
            destacado: true,
          ),
        ],
      ),
    );
  }
}

class _FilaDesglose extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;

  const _FilaDesglose({
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            etiqueta,
            style: TextStyle(
              color: destacado ? colors.ink : colors.inkSoft,
              fontSize: destacado ? 15 : 14,
              fontWeight: destacado ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            color: destacado ? colors.terracottaDeep : colors.ink,
            fontSize: destacado ? 16 : 14,
            fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer sticky con botones contextuales

class _FooterAcciones extends StatelessWidget {
  final PedidoUnificadoModel pedido;
  final bool esSolicitante;
  final _EstadoPedidoVisual estado;
  final bool cargando;
  final bool yaValoro;

  final VoidCallback onAceptar;
  final VoidCallback onDenegar;
  final VoidCallback onCancelarSolicitud;
  final VoidCallback? onCompletar;
  final VoidCallback? onCancelarTransaccion;
  final VoidCallback? onAbrirChat;
  final VoidCallback? onValorar;

  const _FooterAcciones({
    required this.pedido,
    required this.esSolicitante,
    required this.estado,
    required this.cargando,
    required this.yaValoro,
    required this.onAceptar,
    required this.onDenegar,
    required this.onCancelarSolicitud,
    required this.onCompletar,
    required this.onCancelarTransaccion,
    required this.onAbrirChat,
    required this.onValorar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final acciones = _resolverAcciones();

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (acciones.secundariaTexto != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton(
                onPressed:
                    cargando ? null : acciones.secundariaCallback,
                style: TextButton.styleFrom(
                  foregroundColor: colors.terracottaDeep,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
                child: Text(acciones.secundariaTexto!),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: YumButton(
                  text: 'Abrir chat',
                  variant: YumButtonVariant.ghost,
                  fullWidth: true,
                  onPressed: cargando ? null : onAbrirChat,
                ),
              ),
              if (acciones.principalTexto != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: YumButton(
                    text: cargando ? '…' : acciones.principalTexto!,
                    fullWidth: true,
                    onPressed:
                        cargando ? null : acciones.principalCallback,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  _AccionesFooter _resolverAcciones() {
    final esPendiente = pedido.estadoSolicitud == EstadoSolicitud.pendiente;
    final esAceptada = pedido.estadoTransaccion == EstadoTransaccion.aceptada;
    final esCompletada =
        pedido.estadoTransaccion == EstadoTransaccion.completada;

    if (esPendiente && esSolicitante) {
      return _AccionesFooter(
        principalTexto: 'Cancelar',
        principalCallback: onCancelarSolicitud,
      );
    }
    if (esPendiente && !esSolicitante) {
      return _AccionesFooter(
        principalTexto: 'Aceptar',
        principalCallback: onAceptar,
        secundariaTexto: 'Denegar solicitud',
        secundariaCallback: onDenegar,
      );
    }
    if (esAceptada) {
      return _AccionesFooter(
        principalTexto: 'Marcar como entregado',
        principalCallback: onCompletar,
        secundariaTexto: 'Cancelar transacción',
        secundariaCallback: onCancelarTransaccion,
      );
    }
    if (esCompletada && !yaValoro) {
      return _AccionesFooter(
        principalTexto: 'Valorar',
        principalCallback: onValorar,
      );
    }
    // Completada con valoración, denegada, cancelada, reportada → solo chat.
    return const _AccionesFooter();
  }
}

class _AccionesFooter {
  final String? principalTexto;
  final VoidCallback? principalCallback;
  final String? secundariaTexto;
  final VoidCallback? secundariaCallback;

  const _AccionesFooter({
    this.principalTexto,
    this.principalCallback,
    this.secundariaTexto,
    this.secundariaCallback,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge de estado final (cuando el pedido ya está cerrado)

class _BadgeEstadoFinal extends StatelessWidget {
  final _EstadoPedidoVisual estado;
  final bool yaValoro;

  const _BadgeEstadoFinal({required this.estado, required this.yaValoro});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final esExito = estado.tono == _TonoEstado.exito;
    final fondo = esExito
        ? colors.olive.withValues(alpha: 0.18)
        : colors.cream2;
    final texto = esExito
        ? (yaValoro ? 'Pedido entregado · Ya has valorado' : 'Pedido entregado')
        : estado.etiqueta;
    final color = esExito ? colors.oliveDeep : colors.inkSoft;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              esExito
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              texto,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mapeo de estado de pedido a representación visual

enum _TonoEstado { activo, exito, neutro }

class _EstadoPedidoVisual {
  /// Paso del timeline en el que está el pedido (1=Reservado, 2=Aceptado,
  /// 3=Entregado). Si está cancelado/denegado se queda donde estaba.
  final int pasoActual;
  final String etiqueta;
  final _TonoEstado tono;
  final bool mostrarMapa;

  /// Cuando el pedido ya no admite progresión natural (cancelado, denegado,
  /// completado), no se pintan acciones de avance.
  final bool esFinalizado;

  const _EstadoPedidoVisual({
    required this.pasoActual,
    required this.etiqueta,
    required this.tono,
    required this.mostrarMapa,
    required this.esFinalizado,
  });

  static _EstadoPedidoVisual desde(PedidoUnificadoModel pedido) {
    // Estados terminales por solicitud
    switch (pedido.estadoSolicitud) {
      case EstadoSolicitud.denegada:
      case EstadoSolicitud.autoDenegada:
        return const _EstadoPedidoVisual(
          pasoActual: 1,
          etiqueta: 'Denegada',
          tono: _TonoEstado.neutro,
          mostrarMapa: false,
          esFinalizado: true,
        );
      case EstadoSolicitud.cancelada:
        return const _EstadoPedidoVisual(
          pasoActual: 1,
          etiqueta: 'Cancelada',
          tono: _TonoEstado.neutro,
          mostrarMapa: false,
          esFinalizado: true,
        );
    }

    // Estados terminales por transacción
    if (pedido.estadoTransaccion == EstadoTransaccion.cancelada) {
      return const _EstadoPedidoVisual(
        pasoActual: 2,
        etiqueta: 'Cancelada',
        tono: _TonoEstado.neutro,
        mostrarMapa: false,
        esFinalizado: true,
      );
    }
    if (pedido.estadoTransaccion == EstadoTransaccion.reportada) {
      return const _EstadoPedidoVisual(
        pasoActual: 2,
        etiqueta: 'Reportada',
        tono: _TonoEstado.neutro,
        mostrarMapa: false,
        esFinalizado: true,
      );
    }
    if (pedido.estadoTransaccion == EstadoTransaccion.completada) {
      return const _EstadoPedidoVisual(
        pasoActual: 3,
        etiqueta: 'Entregado',
        tono: _TonoEstado.exito,
        mostrarMapa: true,
        esFinalizado: true,
      );
    }

    // En curso
    if (pedido.estadoTransaccion == EstadoTransaccion.aceptada) {
      return const _EstadoPedidoVisual(
        pasoActual: 2,
        etiqueta: 'Aceptado',
        tono: _TonoEstado.activo,
        mostrarMapa: true,
        esFinalizado: false,
      );
    }

    // Pendiente (estado por defecto al crear la solicitud)
    return const _EstadoPedidoVisual(
      pasoActual: 1,
      etiqueta: 'En revisión',
      tono: _TonoEstado.activo,
      mostrarMapa: false,
      esFinalizado: false,
    );
  }
}
