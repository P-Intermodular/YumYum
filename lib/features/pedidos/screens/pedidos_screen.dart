import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/yum_app_bar.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../solicitudes/domain/entities/solicitud_oferta_model.dart';
import '../../solicitudes/providers/solicitud_oferta_providers.dart';
import '../domain/entities/transaccion_model.dart';
import '../providers/panel_pedidos_provider.dart';
import '../providers/transaccion_providers.dart';
import '../widgets/tarjeta_solicitud_oferta.dart';
import '../widgets/tarjeta_transaccion.dart';

/// Pantalla que reúne solicitudes y transacciones del usuario.
class PedidosScreen extends ConsumerWidget {
  const PedidosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panelPedidosAsync = ref.watch(panelPedidosProvider);
    final colors = context.yumColors;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const YumAppBar(title: 'Pedidos', showBack: false),
      body: YumBackground(
        child: panelPedidosAsync.when(
          data: (data) {
            if (data.isEmpty) {
              return Center(
                child: Text(
                  'Todavía no tienes pedidos ni intercambios.',
                  style: TextStyle(color: colors.inkSoft, fontSize: 16),
                ),
              );
            }

            final recibidasPendientes = data.solicitudesRecibidas
                .where((solicitud) => solicitud.estado == EstadoSolicitud.pendiente)
                .toList();
            final otrasRecibidas = data.solicitudesRecibidas
                .where((solicitud) => solicitud.estado != EstadoSolicitud.pendiente)
                .toList();
            final enviadas = data.solicitudesEnviadas;
            final aceptadas = data.transacciones
                .where((transaccion) => transaccion.estado == EstadoTransaccion.aceptada)
                .toList();
            final completadas = data.transacciones
                .where((transaccion) => transaccion.estado == EstadoTransaccion.completada)
                .toList();
            final otrasTransacciones = data.transacciones
                .where(
                  (transaccion) =>
                      transaccion.estado != EstadoTransaccion.aceptada &&
                      transaccion.estado != EstadoTransaccion.completada,
                )
                .toList();

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(solicitudesRecibidasProvider);
                ref.invalidate(solicitudesEnviadasProvider);
                ref.invalidate(transaccionesListProvider);
              },
              child: ListView(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                  bottom: 120,
                  left: 16,
                  right: 16,
                ),
                children: [
                  _buildSeccionSolicitudes(context, 'Solicitudes recibidas', recibidasPendientes, puedeResponder: true),
                  _buildSeccionSolicitudes(context, 'Historial de solicitudes', otrasRecibidas),
                  _buildSeccionSolicitudes(context, 'Solicitudes enviadas', enviadas),
                  _buildSeccionTransacciones(context, 'Aceptados', aceptadas),
                  _buildSeccionTransacciones(context, 'Completados', completadas),
                  _buildSeccionTransacciones(context, 'Otros movimientos', otrasTransacciones),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text(mensajeError(e))),
        ),
      ),
    );
  }

  Widget _buildSeccionSolicitudes(
    BuildContext context,
    String titulo,
    List<SolicitudOfertaModel> solicitudes, {
    bool puedeResponder = false,
  }) {
    if (solicitudes.isEmpty) return const SizedBox.shrink();
    final colors = context.yumColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 12),
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.ink,
            ),
          ),
        ),
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

  Widget _buildSeccionTransacciones(
    BuildContext context,
    String titulo,
    List<TransaccionModel> transacciones,
  ) {
    if (transacciones.isEmpty) return const SizedBox.shrink();
    final colors = context.yumColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 12),
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.ink,
            ),
          ),
        ),
        for (final transaccion in transacciones) ...[
          TarjetaTransaccion(transaccion: transaccion),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
