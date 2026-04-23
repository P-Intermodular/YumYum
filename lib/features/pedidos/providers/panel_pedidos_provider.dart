import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/panel_pedidos_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../solicitudes/providers/solicitud_oferta_repository_provider.dart';
import 'transaccion_repository_provider.dart';

/// Agrega solicitudes y transacciones para construir el panel de pedidos.
final panelPedidosProvider = FutureProvider<PanelPedidosModel>((ref) async {
  final usuario = ref.watch(autenticacionProvider).value;
  if (usuario == null) {
    return const PanelPedidosModel(
      solicitudesRecibidas: [],
      solicitudesEnviadas: [],
      transacciones: [],
    );
  }

  final solicitudRepository = ref.watch(solicitudOfertaRepositoryProvider);
  final transaccionRepository = ref.watch(transaccionRepositoryProvider);

  // El panel necesita combinar tres fuentes distintas, pero la UI solo consume
  // un único modelo agregado.
  final recibidas =
      await solicitudRepository.obtenerSolicitudesRecibidas(usuario.id);
  final enviadas =
      await solicitudRepository.obtenerSolicitudesEnviadas(usuario.id);
  final transacciones =
      await transaccionRepository.obtenerTransacciones(usuario.id);

  return PanelPedidosModel(
    solicitudesRecibidas: recibidas,
    solicitudesEnviadas: enviadas,
    transacciones: transacciones,
  );
});
