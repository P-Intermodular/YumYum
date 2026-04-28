import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/providers_refresher.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../pedidos/domain/entities/transaccion_model.dart';
import '../providers/valoracion_repository_provider.dart';

/// Gestiona el envío de valoraciones sobre transacciones completadas.
final valoracionControllerProvider =
    StateNotifierProvider.autoDispose<ValoracionController, AsyncValue<void>>(
        (ref) {
  return ValoracionController(ref);
});

/// Orquesta la creación de valoraciones y la invalidación de providers.
class ValoracionController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ValoracionController(this._ref) : super(const AsyncValue.data(null));

  /// Envía la valoración calculando automáticamente el producto valorado.
  Future<void> enviarValoracion({
    required TransaccionModel transaccion,
    required int puntuacion,
    String? comentario,
  }) async {
    state = const AsyncValue.loading();
    try {
      final usuario = _ref.read(autenticacionProvider).value!;
      final valoradoId = transaccion.contraparte(usuario.id);
      final productoValoradoId =
          _resolverProductoValorado(transaccion, usuario.id);

      await _ref.read(valoracionRepositoryProvider).crearValoracion(
            transaccionId: transaccion.id,
            valoradorId: usuario.id,
            valoradoId: valoradoId,
            productoValoradoId: productoValoradoId,
            puntuacion: puntuacion,
            comentario: comentario?.trim().isEmpty == true ? null : comentario,
          );

      _ref.refrescarPedidos();
      _ref.refrescarTransaccionDetalle(transaccion.id);
      _ref.refrescarValoracionUsuario(
        transaccionId: transaccion.id,
        usuarioId: usuario.id,
      );
      _ref.refrescarValoracionesRecibidas(valoradoId);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// El plato valorado es siempre el que ha recibido el valorador.
  String? _resolverProductoValorado(
    TransaccionModel transaccion,
    String usuarioId,
  ) {
    final esComprador = transaccion.compradorId == usuarioId;
    if (esComprador) return transaccion.productoId;
    if (transaccion.tipo == TipoOferta.intercambio) {
      return transaccion.productoOfrecidoId;
    }
    return null;
  }
}
