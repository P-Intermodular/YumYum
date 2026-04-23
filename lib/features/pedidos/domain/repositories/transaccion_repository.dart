import '../entities/transaccion_model.dart';

abstract class TransaccionRepository {
  Future<List<TransaccionModel>> obtenerTransacciones(String usuarioId);
  Future<void> completarTransaccion(String transaccionId);
}
