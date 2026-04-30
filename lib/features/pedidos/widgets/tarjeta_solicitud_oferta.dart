import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/feedback/app_feedback.dart';
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
    final coloresEstado = _coloresEstado(solicitud.estado);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        ? Colors.purple.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    solicitud.tipoSolicitud == TipoOferta.intercambio
                        ? Icons.swap_horiz
                        : Icons.shopping_bag_outlined,
                    color: solicitud.tipoSolicitud == TipoOferta.intercambio
                        ? Colors.purple.shade700
                        : Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.tituloProducto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        solicitud.esEntrante
                            ? 'De ${solicitud.nombreContraparte}'
                            : 'Para ${solicitud.nombreContraparte}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      if (solicitud.mensaje?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(
                          solicitud.mensaje!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
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
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: coloresEstado.$1,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _etiquetaEstado(solicitud.estado),
                        style: TextStyle(
                          fontSize: 12,
                          color: coloresEstado.$2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd/MM').format(solicitud.creadoEn),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            if (puedeResponder &&
                solicitud.estado == EstadoSolicitud.pendiente) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _denegar(context, ref),
                      child: const Text('Denegar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _aceptar(context, ref),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ],
            if (!puedeResponder &&
                !solicitud.esEntrante &&
                solicitud.estado == EstadoSolicitud.pendiente) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancelar(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  child: const Text('Cancelar solicitud'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Acepta la solicitud y muestra feedback inmediato en la UI.
  Future<void> _aceptar(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(solicitudOfertaControllerProvider.notifier)
          .aceptar(solicitud.id);

      if (context.mounted) {
        mostrarExito(context, 'Solicitud aceptada');
      }
    } catch (error) {
      if (context.mounted) {
        mostrarError(context, error);
      }
    }
  }

  /// Deniega la solicitud y muestra feedback inmediato en la UI.
  Future<void> _denegar(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(solicitudOfertaControllerProvider.notifier)
          .denegar(solicitud.id);

      if (context.mounted) {
        mostrarExito(context, 'Solicitud denegada');
      }
    } catch (error) {
      if (context.mounted) {
        mostrarError(context, error);
      }
    }
  }

  /// Cancela una solicitud enviada y muestra feedback inmediato en la UI.
  Future<void> _cancelar(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(solicitudOfertaControllerProvider.notifier)
          .cancelar(solicitud.id);

      if (context.mounted) {
        mostrarExito(context, 'Solicitud cancelada');
      }
    } catch (error) {
      if (context.mounted) {
        mostrarError(context, error);
      }
    }
  }

  /// Asigna colores según el estado funcional de la solicitud.
  (Color, Color) _coloresEstado(String estado) {
    switch (estado) {
      case EstadoSolicitud.aceptada:
        return (Colors.green.shade100, Colors.green.shade800);
      case EstadoSolicitud.denegada:
      case EstadoSolicitud.autoDenegada:
      case EstadoSolicitud.cancelada:
        return (Colors.grey.shade200, Colors.grey.shade700);
      default:
        return (Colors.orange.shade100, Colors.orange.shade800);
    }
  }

  /// Devuelve la etiqueta legible que se muestra en la tarjeta.
  String _etiquetaEstado(String estado) {
    switch (estado) {
      case EstadoSolicitud.aceptada:
        return 'Aceptada';
      case EstadoSolicitud.denegada:
        return 'Denegada';
      case EstadoSolicitud.autoDenegada:
        return 'No disponible';
      case EstadoSolicitud.cancelada:
        return 'Cancelada';
      default:
        return 'Pendiente';
    }
  }
}
