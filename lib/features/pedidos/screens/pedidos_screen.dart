import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../solicitudes/domain/entities/solicitud_oferta_model.dart';
import '../domain/entities/transaccion_model.dart';
import '../providers/panel_pedidos_provider.dart';
import '../widgets/tarjeta_solicitud_oferta.dart';
import '../widgets/tarjeta_transaccion.dart';
import '../widgets/titulo_seccion.dart';

/// Pantalla que reúne solicitudes y transacciones del usuario.
class PedidosScreen extends ConsumerWidget {
  const PedidosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panelPedidosAsync = ref.watch(panelPedidosProvider);

    return Scaffold(
      appBar: const YumYumAppBar(titulo: 'Pedidos'),
      body: panelPedidosAsync.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(
              child: Text('Todavía no tienes pedidos ni intercambios.'),
            );
          }

          final recibidasPendientes = data.solicitudesRecibidas
              .where(
                  (solicitud) => solicitud.estado == EstadoSolicitud.pendiente)
              .toList();
          final otrasRecibidas = data.solicitudesRecibidas
              .where(
                  (solicitud) => solicitud.estado != EstadoSolicitud.pendiente)
              .toList();
          final enviadas = data.solicitudesEnviadas;
          final aceptadas = data.transacciones
              .where((transaccion) =>
                  transaccion.estado == EstadoTransaccion.aceptada)
              .toList();
          final completadas = data.transacciones
              .where((transaccion) =>
                  transaccion.estado == EstadoTransaccion.completada)
              .toList();
          final otrasTransacciones = data.transacciones
              .where(
                (transaccion) =>
                    transaccion.estado != EstadoTransaccion.aceptada &&
                    transaccion.estado != EstadoTransaccion.completada,
              )
              .toList();

          return RefreshIndicator(
            // Permite resincronizar el panel completo tras cambios externos.
            onRefresh: () => ref.refresh(panelPedidosProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSeccionSolicitudes(
                  'Solicitudes recibidas',
                  recibidasPendientes,
                  puedeResponder: true,
                ),
                _buildSeccionSolicitudes(
                  'Historial de solicitudes recibidas',
                  otrasRecibidas,
                ),
                _buildSeccionSolicitudes('Solicitudes enviadas', enviadas),
                _buildSeccionTransacciones('Aceptados', aceptadas),
                _buildSeccionTransacciones('Completados', completadas),
                _buildSeccionTransacciones(
                  'Otros movimientos',
                  otrasTransacciones,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(mensajeError(e))),
      ),
    );
  }

  /// Construye una sección homogénea para solicitudes recibidas o enviadas.
  Widget _buildSeccionSolicitudes(
    String titulo,
    List<SolicitudOfertaModel> solicitudes, {
    bool puedeResponder = false,
  }) {
    if (solicitudes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TituloSeccion(titulo),
        for (final solicitud in solicitudes) ...[
          TarjetaSolicitudOferta(
            solicitud: solicitud,
            puedeResponder: puedeResponder,
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  /// Construye una sección homogénea para las transacciones del panel.
  Widget _buildSeccionTransacciones(
    String titulo,
    List<TransaccionModel> transacciones,
  ) {
    if (transacciones.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TituloSeccion(titulo),
        for (final transaccion in transacciones) ...[
          TarjetaTransaccion(transaccion: transaccion),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
