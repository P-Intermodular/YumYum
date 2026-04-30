import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/providers_refresher.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../pedidos/domain/entities/transaccion_model.dart';
import '../providers/valoracion_repository_provider.dart';

/// Gestiona el envío de valoraciones sobre transacciones completadas.
final valoracionControllerProvider =
    NotifierProvider.autoDispose<ValoracionController, AsyncValue<void>>(
  ValoracionController.new,
);

/// Orquesta la creación de valoraciones y la invalidación de providers.
class ValoracionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Envía la valoración calculando automáticamente el producto valorado.
  Future<void> enviarValoracion({
    required TransaccionModel transaccion,
    required int puntuacion,
    String? comentario,
  }) async {
    final keepAlive = ref.keepAlive();
    state = const AsyncValue.loading();
    try {
      final usuario = ref.read(autenticacionProvider).value!;
      final valoradoId = transaccion.contraparte(usuario.id);
      final productoValoradoId =
          _resolverProductoValorado(transaccion, usuario.id);

      await ref.read(valoracionRepositoryProvider).crearValoracion(
            transaccionId: transaccion.id,
            valoradorId: usuario.id,
            valoradoId: valoradoId,
            productoValoradoId: productoValoradoId,
            puntuacion: puntuacion,
            comentario: comentario?.trim().isEmpty == true ? null : comentario,
          );

      ref.refrescarPedidos();
      ref.refrescarTransaccionDetalle(transaccion.id);
      ref.refrescarValoracionUsuario(
        transaccionId: transaccion.id,
        usuarioId: usuario.id,
      );
      ref.refrescarValoracionesRecibidas(valoradoId);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      keepAlive.close();
    }
  }

  /// El plato valorado es siempre el que ha recibido el valorador.
  String? _resolverProductoValorado(
    TransaccionModel transaccion,
    String usuarioId,
  ) {
    final esSolicitante = transaccion.solicitanteId == usuarioId;
    if (esSolicitante) return transaccion.productoId;
    if (transaccion.tipo == TipoOferta.intercambio) {
      return transaccion.productoOfrecidoId;
    }
    return null;
  }
}
