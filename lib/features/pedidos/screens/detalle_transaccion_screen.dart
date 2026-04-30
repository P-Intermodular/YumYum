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
import '../../../core/widgets/avatar_usuario.dart';
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
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar transacción'),
        content: const Text(
          '¿Seguro que quieres cancelar esta transacción? '
          'Los productos volverán a estar disponibles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      ),
      body: transaccionAsync.when(
        data: (transaccion) {
          if (transaccion == null || usuario == null) {
            return const Center(child: Text('Transacción no encontrada'));
          }
          return _buildContenido(transaccion, usuario.id, cargando);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(mensajeError(e))),
      ),
    );
  }

  Widget _buildContenido(
    TransaccionModel transaccion,
    String usuarioId,
    bool cargando,
  ) {
    final precio = transaccion.tipo == TipoOferta.intercambio
        ? 'Trueque'
        : '${transaccion.total?.toStringAsFixed(2) ?? '--'} EUR';
    final esAceptada = transaccion.estado == EstadoTransaccion.aceptada;
    final esCompletada = transaccion.estado == EstadoTransaccion.completada;
    final mostrarMapa = esAceptada || esCompletada;

    final valoracionAsync = ref.watch(
      valoracionUsuarioProvider((transaccion.id, usuarioId)),
    );
    final yaValoro = valoracionAsync.value != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F4A5B),
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
          _buildFilaInfo('Plato', transaccion.tituloProducto),
          _buildFilaInfo('Tipo', precio),
          _buildFilaInfo(
            'Estado',
            _etiquetaEstado(transaccion.estado),
          ),
          _buildFilaInfo(
            'Fecha',
            DateFormat('dd/MM/yyyy HH:mm').format(transaccion.creadoEn),
          ),
          if (transaccion.completadoEn != null)
            _buildFilaInfo(
              'Completado',
              DateFormat('dd/MM/yyyy HH:mm').format(transaccion.completadoEn!),
            ),
          const SizedBox(height: 24),
          if (mostrarMapa) ...[
            const Text(
              'Lugar de recogida',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4A5B),
              ),
            ),
            const SizedBox(height: 8),
            _buildMapaRecogida(transaccion.productoId),
            const SizedBox(height: 24),
          ],
          if (esAceptada)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cargando ? null : () => _completar(transaccion.id),
                child: cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Marcar como realizado'),
              ),
            ),
          if (esAceptada) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: cargando ? null : () => _cancelar(transaccion.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                ),
                child: const Text('Cancelar transacción'),
              ),
            ),
          ],
          if (esCompletada && !yaValoro)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(
                  RutasApp.valorarTransaccion(transaccion.id),
                ),
                child: const Text('Valorar'),
              ),
            ),
          if (esCompletada && yaValoro)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ya has valorado esta transacción',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
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
    final ubicacionAsync = ref.watch(ubicacionExactaProvider(productoId));

    return ubicacionAsync.when(
      data: (latLng) => latLng == null
          ? Text(
              'Lugar de recogida no disponible aún.',
              style: TextStyle(color: Colors.grey.shade700),
            )
          : _MiniMapaRecogida(punto: latLng),
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Text(
        'Lugar de recogida no disponible aún.',
        style: TextStyle(color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildFilaInfo(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              etiqueta,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F4A5B),
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
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
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
                    color: colorScheme.primary,
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
