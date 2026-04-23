import '../entities/transaccion_model.dart';

/// Contrato de lectura y cierre de transacciones.
abstract class TransaccionRepository {
  /// Recupera las transacciones donde participa el usuario indicado.
  Future<List<TransaccionModel>> obtenerTransacciones(String usuarioId);

  /// Marca una transacción como completada mediante la RPC correspondiente.
  Future<void> completarTransaccion(String transaccionId);
}
