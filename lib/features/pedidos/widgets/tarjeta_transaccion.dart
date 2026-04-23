import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/estados_app.dart';
import '../domain/entities/transaccion_model.dart';

class TarjetaTransaccion extends StatelessWidget {
  final TransaccionModel transaccion;

  const TarjetaTransaccion({super.key, required this.transaccion});

  @override
  Widget build(BuildContext context) {
    final coloresEstado = _coloresEstado(transaccion.estado);
    final precio = transaccion.tipo == TipoOferta.intercambio
        ? 'Trueque'
        : '${transaccion.total?.toStringAsFixed(2) ?? '--'} EUR';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fastfood, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaccion.tituloProducto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaccion.nombreContraparte,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
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
                      _etiquetaEstado(transaccion.estado),
                      style: TextStyle(
                        fontSize: 12,
                        color: coloresEstado.$2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  precio,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(transaccion.creadoEn),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _coloresEstado(String estado) {
    switch (estado) {
      case EstadoTransaccion.completada:
        return (Colors.grey.shade200, Colors.grey.shade700);
      case EstadoTransaccion.aceptada:
        return (Colors.green.shade100, Colors.green.shade800);
      case EstadoTransaccion.reportada:
        return (Colors.red.shade100, Colors.red.shade800);
      default:
        return (Colors.orange.shade100, Colors.orange.shade800);
    }
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
