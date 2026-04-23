import '../../../solicitudes/domain/entities/solicitud_oferta_model.dart';
import 'transaccion_model.dart';

class PanelPedidosModel {
  final List<SolicitudOfertaModel> solicitudesRecibidas;
  final List<SolicitudOfertaModel> solicitudesEnviadas;
  final List<TransaccionModel> transacciones;

  const PanelPedidosModel({
    required this.solicitudesRecibidas,
    required this.solicitudesEnviadas,
    required this.transacciones,
  });

  bool get isEmpty =>
      solicitudesRecibidas.isEmpty &&
      solicitudesEnviadas.isEmpty &&
      transacciones.isEmpty;
}
