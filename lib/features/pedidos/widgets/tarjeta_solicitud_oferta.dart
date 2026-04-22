import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/solicitud_oferta_model.dart';
import '../../chat/providers/chat_providers.dart';
import '../../producto/providers/producto_providers.dart';
import '../../solicitudes/repositories/solicitud_oferta_repository.dart';
import '../providers/panel_pedidos_provider.dart';

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
                    color: solicitud.tipoSolicitud == 'intercambio'
                        ? Colors.purple.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    solicitud.tipoSolicitud == 'intercambio'
                        ? Icons.swap_horiz
                        : Icons.shopping_bag_outlined,
                    color: solicitud.tipoSolicitud == 'intercambio'
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
            if (puedeResponder && solicitud.estado == 'pendiente') ...[
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
          ],
        ),
      ),
    );
  }

  Future<void> _aceptar(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(solicitudOfertaRepositoryProvider)
          .aceptarSolicitudOferta(solicitud.id);
      _refrescarDatos(ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud aceptada')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> _denegar(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(solicitudOfertaRepositoryProvider)
          .denegarSolicitudOferta(solicitud.id);
      _refrescarDatos(ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud denegada')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  void _refrescarDatos(WidgetRef ref) {
    ref.invalidate(panelPedidosProvider);
    ref.invalidate(productosProvider);
    ref.invalidate(listaChatsProvider);
  }

  (Color, Color) _coloresEstado(String estado) {
    switch (estado) {
      case 'aceptada':
        return (Colors.green.shade100, Colors.green.shade800);
      case 'denegada':
      case 'auto_denegada':
      case 'cancelada':
        return (Colors.grey.shade200, Colors.grey.shade700);
      default:
        return (Colors.orange.shade100, Colors.orange.shade800);
    }
  }

  String _etiquetaEstado(String estado) {
    switch (estado) {
      case 'aceptada':
        return 'Aceptada';
      case 'denegada':
        return 'Denegada';
      case 'auto_denegada':
        return 'No disponible';
      case 'cancelada':
        return 'Cancelada';
      default:
        return 'Pendiente';
    }
  }
}
