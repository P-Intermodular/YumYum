import '../entities/transaccion_model.dart';

/// Contrato de lectura y cierre de transacciones.
abstract class TransaccionRepository {
  /// Recupera las transacciones donde participa el usuario indicado.
  Future<List<TransaccionModel>> obtenerTransacciones(String usuarioId);

  /// Recupera una transacción concreta por su identificador.
  Future<TransaccionModel?> obtenerTransaccionPorId(
    String transaccionId,
    String usuarioId,
  );

  /// Marca una transacción como completada mediante la RPC correspondiente.
  Future<void> completarTransaccion(String transaccionId);

  /// Cancela una transacción aceptada y devuelve los productos a disponible.
  Future<void> cancelarTransaccion(String transaccionId);
}
