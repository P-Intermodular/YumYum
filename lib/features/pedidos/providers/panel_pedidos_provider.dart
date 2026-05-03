import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/panel_pedidos_model.dart';

import '../../solicitudes/providers/solicitud_oferta_providers.dart';
import 'transaccion_providers.dart';

/// Agrega solicitudes y transacciones para construir el panel de pedidos.
final panelPedidosProvider = Provider<AsyncValue<PanelPedidosModel>>((ref) {
  final recibidas = ref.watch(solicitudesRecibidasProvider);
  final enviadas = ref.watch(solicitudesEnviadasProvider);
  final transacciones = ref.watch(transaccionesListProvider);

  // Si CUALQUIERA está cargando, el panel está cargando (en la primera vez).
  if (recibidas.isLoading || enviadas.isLoading || transacciones.isLoading) {
    return const AsyncValue.loading();
  }

  // Si CUALQUIERA tiene error, el panel propaga el error.
  final error = recibidas.error ?? enviadas.error ?? transacciones.error;
  if (error != null) {
    final st =
        recibidas.stackTrace ?? enviadas.stackTrace ?? transacciones.stackTrace;
    return AsyncValue.error(error, st ?? StackTrace.current);
  }

  // Si todos tienen datos, construimos el modelo final.
  return AsyncValue.data(
    PanelPedidosModel(
      solicitudesRecibidas: recibidas.requireValue,
      solicitudesEnviadas: enviadas.requireValue,
      transacciones: transacciones.requireValue,
    ),
  );
});
