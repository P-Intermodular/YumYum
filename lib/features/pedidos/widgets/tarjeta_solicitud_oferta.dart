import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../../../core/widgets/ui/yum_card.dart';
import '../../solicitudes/controllers/solicitud_oferta_controller.dart';
import '../../solicitudes/domain/entities/solicitud_oferta_model.dart';

/// Tarjeta visual que resume una solicitud y permite responder si procede.
class TarjetaSolicitudOferta extends ConsumerWidget {
  final SolicitudOfertaModel solicitud;
  final bool puedeResponder;

  const TarjetaSolicitudOferta({
    super.key,
    required this.solicitud,
    required this.puedeResponder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    final coloresEstado = _coloresEstado(solicitud.estado, context);

    return YumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: solicitud.tipoSolicitud == TipoOferta.intercambio
                      ? colors.mustard.withValues(alpha: 0.2)
                      : colors.terracotta.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: solicitud.tipoSolicitud == TipoOferta.intercambio
                        ? colors.mustard.withValues(alpha: 0.5)
                        : colors.terracotta.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  solicitud.tipoSolicitud == TipoOferta.intercambio
                      ? Icons.swap_horiz
                      : Icons.shopping_bag_outlined,
                  color: solicitud.tipoSolicitud == TipoOferta.intercambio
                      ? colors.mustard
                      : colors.terracotta,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      solicitud.tituloProducto,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      solicitud.esEntrante
                          ? 'De ${solicitud.nombreContraparte}'
                          : 'Para ${solicitud.nombreContraparte}',
                      style: TextStyle(color: colors.inkSoft, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _resumenCantidades(),
                      style: TextStyle(
                        color: colors.oliveDeep,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (solicitud.mensaje?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        solicitud.mensaje!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.inkSoft,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: coloresEstado.$1,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _etiquetaEstado(solicitud.estado),
                      style: TextStyle(
                        fontSize: 11,
                        color: coloresEstado.$2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd/MM').format(solicitud.creadoEn),
                    style: TextStyle(fontSize: 12, color: colors.inkSoft),
                  ),
                ],
              ),
            ],
          ),
          if (puedeResponder &&
              solicitud.estado == EstadoSolicitud.pendiente) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: YumButton(
                    text: 'Denegar',
                    variant: YumButtonVariant.ghost,
                    onPressed: () => _denegar(context, ref),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: YumButton(
                    text: 'Aceptar',
                    variant: YumButtonVariant.primary,
                    onPressed: () => _aceptar(context, ref),
                  ),
                ),
              ],
            ),
          ],
          if (!puedeResponder &&
              !solicitud.esEntrante &&
              solicitud.estado == EstadoSolicitud.pendiente) ...[
            const SizedBox(height: 20),
            YumButton(
              text: 'Cancelar solicitud',
              fullWidth: true,
              variant: YumButtonVariant.ghost,
              fgColor: Colors.red.shade700,
              onPressed: () => _cancelar(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _aceptar(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(solicitudOfertaControllerProvider.notifier).aceptar(solicitud.id);
      if (context.mounted) mostrarExito(context, 'Solicitud aceptada');
    } catch (error) {
      if (context.mounted) mostrarError(context, error);
    }
  }

  Future<void> _denegar(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(solicitudOfertaControllerProvider.notifier).denegar(solicitud.id);
      if (context.mounted) mostrarExito(context, 'Solicitud denegada');
    } catch (error) {
      if (context.mounted) mostrarError(context, error);
    }
  }

  Future<void> _cancelar(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(solicitudOfertaControllerProvider.notifier).cancelar(solicitud.id);
      if (context.mounted) mostrarExito(context, 'Solicitud cancelada');
    } catch (error) {
      if (context.mounted) mostrarError(context, error);
    }
  }

  (Color, Color) _coloresEstado(String estado, BuildContext context) {
    final colors = context.yumColors;
    switch (estado) {
      case EstadoSolicitud.aceptada:
        return (Colors.green.shade100, Colors.green.shade800);
      case EstadoSolicitud.denegada:
      case EstadoSolicitud.autoDenegada:
      case EstadoSolicitud.cancelada:
        return (colors.line, colors.inkSoft);
      default:
        return (colors.mustard.withValues(alpha: 0.2), colors.ink);
    }
  }

  String _resumenCantidades() {
    final racion =
        solicitud.cantidad == 1 ? 'ración' : 'raciones';
    if (solicitud.tipoSolicitud == TipoOferta.intercambio) {
      final ofrecidas = solicitud.cantidadOfrecida ?? 1;
      final racionOfr = ofrecidas == 1 ? 'ración' : 'raciones';
      return '${solicitud.cantidad} $racion ↔ $ofrecidas $racionOfr de tu plato';
    }
    return '${solicitud.cantidad} $racion';
  }

  String _etiquetaEstado(String estado) {
    switch (estado) {
      case EstadoSolicitud.aceptada: return 'Aceptada';
      case EstadoSolicitud.denegada: return 'Denegada';
      case EstadoSolicitud.autoDenegada: return 'No disponible';
      case EstadoSolicitud.cancelada: return 'Cancelada';
      default: return 'Pendiente';
    }
  }
}
