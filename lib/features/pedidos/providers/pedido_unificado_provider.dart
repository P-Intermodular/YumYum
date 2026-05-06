import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../domain/entities/pedido_unificado_model.dart';
import 'pedido_unificado_repository_provider.dart';

/// Carga el VM unificado del pedido a partir de una referencia (solicitud o
/// transacción). Si la sesión está vacía devuelve `null` igual que el resto
/// de providers de pedidos.
final pedidoUnificadoProvider =
    FutureProvider.autoDispose.family<PedidoUnificadoModel?, PedidoRef>(
  (ref, pedidoRef) async {
    final usuario = ref.watch(autenticacionProvider).value;
    if (usuario == null) return null;

    final repo = ref.watch(pedidoUnificadoRepositoryProvider);
    return switch (pedidoRef) {
      PedidoPorSolicitud(:final solicitudId) =>
        repo.obtenerPorSolicitud(solicitudId, usuario.id),
      PedidoPorTransaccion(:final transaccionId) =>
        repo.obtenerPorTransaccion(transaccionId, usuario.id),
    };
  },
);
