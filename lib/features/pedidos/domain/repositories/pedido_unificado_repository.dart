import '../entities/pedido_unificado_model.dart';

/// Contrato de lectura del pedido unificado a partir de solicitud o transacción.
abstract class PedidoUnificadoRepository {
  /// Recupera el pedido unificado a partir del id de solicitud.
  Future<PedidoUnificadoModel?> obtenerPorSolicitud(
    String solicitudId,
    String usuarioId,
  );

  /// Recupera el pedido unificado a partir del id de transacción.
  ///
  /// Internamente resuelve la solicitud asociada y emite el mismo VM unificado
  /// que [obtenerPorSolicitud], para que la UI no dependa del origen.
  Future<PedidoUnificadoModel?> obtenerPorTransaccion(
    String transaccionId,
    String usuarioId,
  );
}
