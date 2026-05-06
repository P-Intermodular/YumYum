import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/yum_card.dart';
import '../domain/entities/transaccion_model.dart';

/// Tarjeta visual que resume una transacción aceptada o completada.
class TarjetaTransaccion extends StatelessWidget {
  final TransaccionModel transaccion;

  const TarjetaTransaccion({super.key, required this.transaccion});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final coloresEstado = _coloresEstado(transaccion.estado, context);
    final precio = transaccion.tipo == TipoOferta.intercambio
        ? 'Trueque'
        : '${transaccion.total?.toStringAsFixed(2) ?? '--'} €';

    return YumCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push(
          RutasApp.transaccionDetalle(transaccion.id),
        ),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.cream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.line),
                ),
                child: Icon(Icons.fastfood, color: colors.terracotta, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaccion.tituloProducto,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaccion.nombreContraparte,
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
                    const SizedBox(height: 12),
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
                        _etiquetaEstado(transaccion.estado),
                        style: TextStyle(
                          fontSize: 11,
                          color: coloresEstado.$2,
                          fontWeight: FontWeight.bold,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd/MM/yyyy').format(transaccion.creadoEn),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.inkSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resumenCantidades() {
    final racion = transaccion.cantidad == 1 ? 'ración' : 'raciones';
    if (transaccion.tipo == TipoOferta.intercambio) {
      final ofrecidas = transaccion.cantidadOfrecida ?? 1;
      final racionOfr = ofrecidas == 1 ? 'ración' : 'raciones';
      return '${transaccion.cantidad} $racion ↔ $ofrecidas $racionOfr de tu plato';
    }
    return '${transaccion.cantidad} $racion';
  }

  (Color, Color) _coloresEstado(String estado, BuildContext context) {
    final colors = context.yumColors;
    switch (estado) {
      case EstadoTransaccion.completada:
        return (colors.line, colors.inkSoft);
      case EstadoTransaccion.aceptada:
        return (colors.olive.withValues(alpha: 0.18), colors.oliveDeep);
      case EstadoTransaccion.reportada:
        return (colors.tomato.withValues(alpha: 0.18), colors.terracottaDeep);
      default:
        return (colors.mustard.withValues(alpha: 0.22), colors.ink);
    }
  }

  String _etiquetaEstado(String estado) {
    switch (estado) {
      case EstadoTransaccion.completada: return 'Completado';
      case EstadoTransaccion.aceptada: return 'Aceptado';
      case EstadoTransaccion.reportada: return 'Reportado';
      case EstadoTransaccion.cancelada: return 'Cancelado';
      default: return 'Pendiente';
    }
  }
}
