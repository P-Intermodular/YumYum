import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/solicitud_oferta_model.dart';
import '../../../models/transaccion_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../solicitudes/repositories/solicitud_oferta_repository.dart';
import '../repositories/transaccion_repository.dart';

class PanelPedidosData {
  final List<SolicitudOfertaModel> solicitudesRecibidas;
  final List<SolicitudOfertaModel> solicitudesEnviadas;
  final List<TransaccionModel> transacciones;

  const PanelPedidosData({
    required this.solicitudesRecibidas,
    required this.solicitudesEnviadas,
    required this.transacciones,
  });

  bool get isEmpty =>
      solicitudesRecibidas.isEmpty &&
      solicitudesEnviadas.isEmpty &&
      transacciones.isEmpty;
}

final panelPedidosProvider = FutureProvider<PanelPedidosData>((ref) async {
  final usuario = ref.watch(autenticacionProvider).value;
  if (usuario == null) {
    return const PanelPedidosData(
      solicitudesRecibidas: [],
      solicitudesEnviadas: [],
      transacciones: [],
    );
  }

  final solicitudRepository = ref.watch(solicitudOfertaRepositoryProvider);
  final transaccionRepository = ref.watch(transaccionRepositoryProvider);

  final recibidas =
      await solicitudRepository.obtenerSolicitudesRecibidas(usuario.id);
  final enviadas =
      await solicitudRepository.obtenerSolicitudesEnviadas(usuario.id);
  final transacciones =
      await transaccionRepository.obtenerTransacciones(usuario.id);

  return PanelPedidosData(
    solicitudesRecibidas: recibidas,
    solicitudesEnviadas: enviadas,
    transacciones: transacciones,
  );
});
