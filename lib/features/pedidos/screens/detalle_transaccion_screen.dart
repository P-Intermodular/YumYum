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
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../../../core/widgets/ui/yum_card.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../producto/providers/ubicacion_exacta_provider.dart';
import '../../valoraciones/providers/valoracion_providers.dart';
import '../controllers/transaccion_controller.dart';
import '../domain/entities/transaccion_model.dart';
import '../providers/transaccion_providers.dart';
import '../widgets/insignia_valoracion_compacta.dart';

/// Pantalla de detalle de una transacción con acciones contextuales.
class DetalleTransaccionScreen extends ConsumerStatefulWidget {
  final String transaccionId;

  const DetalleTransaccionScreen({super.key, required this.transaccionId});

  @override
  ConsumerState<DetalleTransaccionScreen> createState() =>
      _DetalleTransaccionScreenState();
}

class _DetalleTransaccionScreenState
    extends ConsumerState<DetalleTransaccionScreen> {
  Future<void> _completar(String transaccionId) async {
    try {
      await ref
          .read(transaccionControllerProvider.notifier)
          .completar(transaccionId);

      if (!mounted) return;
      mostrarExito(context, 'Transacción completada');
      context.push(RutasApp.valorarTransaccion(transaccionId));
    } catch (error) {
      if (mounted) {
        mostrarError(context, error);
      }
    }
  }

  Future<void> _cancelar(String transaccionId) async {
    final colors = Theme.of(context).extension<YumColors>()!;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.line),
        ),
        title: Text(
          'Cancelar transacción',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                color: colors.ink,
              ),
        ),
        content: Text(
          '¿Seguro que quieres cancelar esta transacción? Los productos volverán a estar disponibles.',
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
            child: const Text('Cancelar transacción'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    try {
      await ref
          .read(transaccionControllerProvider.notifier)
          .cancelar(transaccionId);

      if (!mounted) return;
      mostrarExito(context, 'Transacción cancelada');
    } catch (error) {
      if (mounted) {
        mostrarError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaccionAsync =
        ref.watch(transaccionDetalleProvider(widget.transaccionId));
    final cargando = ref.watch(transaccionControllerProvider).isLoading;
    final usuario = ref.watch(autenticacionProvider).value;

    return Scaffold(
      appBar: const YumYumAppBar(
        titulo: 'Detalle',
        mostrarBotonVolver: true,
        mostrarBotonPerfil: false,
      ),
      body: YumBackground(
        child: transaccionAsync.when(
          data: (transaccion) {
            if (transaccion == null || usuario == null) {
              return _buildMensajeCentrado('Transacción no encontrada');
            }
            return _buildContenido(transaccion, usuario.id, cargando);
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
    TransaccionModel transaccion,
    String usuarioId,
    bool cargando,
  ) {
    final colors = context.yumColors;
    final precio = transaccion.tipo == TipoOferta.intercambio
        ? 'Trueque'
        : '${transaccion.total?.toStringAsFixed(2) ?? '--'} €';
    final esAceptada = transaccion.estado == EstadoTransaccion.aceptada;
    final esCompletada = transaccion.estado == EstadoTransaccion.completada;
    final mostrarMapa = esAceptada || esCompletada;

    final valoracionAsync = ref.watch(
      valoracionUsuarioProvider((transaccion.id, usuarioId)),
    );
    final yaValoro = valoracionAsync.value != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                AvatarUsuario(
                  nombre: transaccion.nombreContraparte,
                  identificadorColor: transaccion.contraparte(usuarioId),
                  urlImagen: transaccion.urlAvatarContraparte,
                  radius: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  transaccion.nombreContraparte,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        color: colors.ink,
                      ),
                ),
                const SizedBox(height: 4),
                InsigniaValoracionCompacta(
                  valoracion: transaccion.valoracionMediaContraparte,
                  cantidad: transaccion.numeroValoracionesContraparte,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          YumCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildFilaInfo('Plato', transaccion.tituloProducto),
                _buildFilaInfo('Tipo', precio),
                _buildFilaInfo('Estado', _etiquetaEstado(transaccion.estado)),
                _buildFilaInfo(
                  'Fecha',
                  DateFormat('dd/MM/yyyy HH:mm').format(transaccion.creadoEn),
                ),
                if (transaccion.completadoEn != null)
                  _buildFilaInfo(
                    'Completado',
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(transaccion.completadoEn!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (mostrarMapa) ...[
            Text(
              'Lugar de recogida',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    color: colors.ink,
                  ),
            ),
            const SizedBox(height: 8),
            _buildMapaRecogida(transaccion.productoId),
            const SizedBox(height: 24),
          ],
          if (esAceptada) ...[
            YumButton(
              text: cargando ? 'Marcando…' : 'Marcar como realizado',
              fullWidth: true,
              onPressed: cargando ? null : () => _completar(transaccion.id),
            ),
            const SizedBox(height: 8),
            YumButton(
              text: 'Cancelar transacción',
              fullWidth: true,
              variant: YumButtonVariant.ghost,
              fgColor: colors.terracottaDeep,
              onPressed: cargando ? null : () => _cancelar(transaccion.id),
            ),
          ],
          if (esCompletada && !yaValoro)
            YumButton(
              text: 'Valorar',
              fullWidth: true,
              icon: const Icon(Icons.star_outline_rounded),
              onPressed: () => context.push(
                RutasApp.valorarTransaccion(transaccion.id),
              ),
            ),
          if (esCompletada && yaValoro)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.olive.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: colors.oliveDeep,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ya has valorado esta transacción',
                      style: TextStyle(
                        color: colors.oliveDeep,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapaRecogida(String productoId) {
    final colors = context.yumColors;
    final ubicacionAsync = ref.watch(ubicacionExactaProvider(productoId));

    return ubicacionAsync.when(
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
    );
  }

  Widget _buildFilaInfo(String etiqueta, String valor) {
    final colors = context.yumColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              etiqueta,
              style: TextStyle(
                color: colors.inkSoft,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.ink,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _etiquetaEstado(String estado) {
    switch (estado) {
      case EstadoTransaccion.completada:
        return 'Completado';
      case EstadoTransaccion.aceptada:
        return 'Aceptado';
      case EstadoTransaccion.reportada:
        return 'Reportado';
      case EstadoTransaccion.cancelada:
        return 'Cancelado';
      default:
        return 'Pendiente';
    }
  }
}

/// Mapa de solo lectura que muestra el punto exacto de recogida.
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
