import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers_refresher.dart';
import '../domain/entities/transaccion_model.dart';
import '../providers/transaccion_providers.dart';
import '../providers/transaccion_repository_provider.dart';

/// Gestiona la operación de completar una transacción aceptada.
final transaccionControllerProvider =
    NotifierProvider.autoDispose<TransaccionController, AsyncValue<void>>(
  TransaccionController.new,
);

/// Orquesta el cierre de transacciones y la invalidación de providers.
class TransaccionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Marca la transacción como completada y refresca las vistas afectadas.
  Future<void> completar(String transaccionId) async {
    final keepAlive = ref.keepAlive();
    state = const AsyncValue.loading();
    try {
      final transaccion =
          ref.read(transaccionDetalleProvider(transaccionId)).value;

      await ref
          .read(transaccionRepositoryProvider)
          .completarTransaccion(transaccionId);

      _refrescarTrasAccion(transaccionId, transaccion);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      keepAlive.close();
    }
  }

  /// Cancela una transacción aceptada y refresca las vistas afectadas.
  Future<void> cancelar(String transaccionId) async {
    final keepAlive = ref.keepAlive();
    state = const AsyncValue.loading();
    try {
      final transaccion =
          ref.read(transaccionDetalleProvider(transaccionId)).value;

      await ref
          .read(transaccionRepositoryProvider)
          .cancelarTransaccion(transaccionId);

      _refrescarTrasAccion(transaccionId, transaccion);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      keepAlive.close();
    }
  }

  /// Invalida providers comunes tras completar o cancelar una transacción.
  void _refrescarTrasAccion(
    String transaccionId,
    TransaccionModel? transaccion,
  ) {
    ref.refrescarPedidos();
    ref.refrescarTransaccionDetalle(transaccionId);
    ref.refrescarCatalogo();

    if (transaccion != null) {
      ref.refrescarProductoDetalle(transaccion.productoId);

      final productoOfrecidoId = transaccion.productoOfrecidoId;
      if (productoOfrecidoId != null) {
        ref.refrescarProductoDetalle(productoOfrecidoId);
      }
    }
  }
}
