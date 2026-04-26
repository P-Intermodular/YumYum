import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/panel_pedidos_provider.dart';
import '../providers/transaccion_providers.dart';
import '../providers/transaccion_repository_provider.dart';

/// Gestiona la operación de completar una transacción aceptada.
final transaccionControllerProvider = StateNotifierProvider.autoDispose<
    TransaccionController, AsyncValue<void>>((ref) {
  return TransaccionController(ref);
});

/// Orquesta el cierre de transacciones y la invalidación de providers.
class TransaccionController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  TransaccionController(this._ref) : super(const AsyncValue.data(null));

  /// Marca la transacción como completada y refresca las vistas afectadas.
  Future<void> completar(String transaccionId) async {
    state = const AsyncValue.loading();
    try {
      await _ref
          .read(transaccionRepositoryProvider)
          .completarTransaccion(transaccionId);
      _ref.invalidate(panelPedidosProvider);
      _ref.invalidate(transaccionDetalleProvider(transaccionId));
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
