import '../../../solicitudes/domain/entities/solicitud_oferta_model.dart';
import 'transaccion_model.dart';

/// Agrega la información necesaria para pintar la pantalla de pedidos.
class PanelPedidosModel {
  final List<SolicitudOfertaModel> solicitudesRecibidas;
  final List<SolicitudOfertaModel> solicitudesEnviadas;
  final List<TransaccionModel> transacciones;

  const PanelPedidosModel({
    required this.solicitudesRecibidas,
    required this.solicitudesEnviadas,
    required this.transacciones,
  });

  /// Indica si el panel no tiene solicitudes ni transacciones que mostrar.
  bool get isEmpty =>
      solicitudesRecibidas.isEmpty &&
      solicitudesEnviadas.isEmpty &&
      transacciones.isEmpty;
}
