import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumyum/core/constants/estados_app.dart';
import 'package:yumyum/core/supabase/supabase_client_provider.dart';
import 'package:yumyum/features/auth/controllers/auth_controller.dart';
import 'package:yumyum/features/auth/providers/auth_repository_provider.dart';
import 'package:yumyum/features/pedidos/controllers/transaccion_controller.dart';
import 'package:yumyum/features/pedidos/domain/entities/transaccion_model.dart';
import 'package:yumyum/features/pedidos/domain/repositories/transaccion_repository.dart';
import 'package:yumyum/features/pedidos/providers/transaccion_providers.dart';
import 'package:yumyum/features/pedidos/providers/transaccion_repository_provider.dart';

import '../../../helpers/auth_test_utils.dart';

void main() {
  group('TransaccionController', () {
    test('completa una transaccion y vuelve a estado data', () async {
      final repository = _TransaccionRepositoryFake(_transaccion());
      final container = ProviderContainer(
        overrides: [
          autenticacionRepositoryProvider.overrideWithValue(
            AuthRepositoryFake(usuarioActual: usuarioTest()),
          ),
          supabaseClientProvider.overrideWithValue(supabaseTestClient()),
          transaccionRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      container.read(autenticacionProvider);
      await container.pump();
      await container.read(transaccionDetalleProvider('transaccion-1').future);

      await container
          .read(transaccionControllerProvider.notifier)
          .completar('transaccion-1');

      expect(repository.transaccionCompletadaId, 'transaccion-1');
      expect(container.read(transaccionControllerProvider).isLoading, false);
      expect(container.read(transaccionControllerProvider).hasError, false);
    });

    test('cancela una transaccion aceptada y vuelve a estado data', () async {
      final repository = _TransaccionRepositoryFake(_transaccion());
      final container = ProviderContainer(
        overrides: [
          autenticacionRepositoryProvider.overrideWithValue(
            AuthRepositoryFake(usuarioActual: usuarioTest()),
          ),
          supabaseClientProvider.overrideWithValue(supabaseTestClient()),
          transaccionRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      container.read(autenticacionProvider);
      await container.pump();
      await container.read(transaccionDetalleProvider('transaccion-1').future);

      await container
          .read(transaccionControllerProvider.notifier)
          .cancelar('transaccion-1');

      expect(repository.transaccionCanceladaId, 'transaccion-1');
      expect(container.read(transaccionControllerProvider).isLoading, false);
      expect(container.read(transaccionControllerProvider).hasError, false);
    });
  });
}

TransaccionModel _transaccion() {
  return TransaccionModel(
    id: 'transaccion-1',
    tipo: TipoOferta.intercambio,
    estado: EstadoTransaccion.aceptada,
    productoId: 'producto-1',
    productoOfrecidoId: 'producto-2',
    solicitanteId: 'usuario-1',
    propietarioId: 'usuario-2',
    tituloProducto: 'Tarta',
    nombreContraparte: 'Luis',
    creadoEn: DateTime(2026),
  );
}

class _TransaccionRepositoryFake implements TransaccionRepository {
  final TransaccionModel transaccion;
  String? transaccionCompletadaId;
  String? transaccionCanceladaId;

  _TransaccionRepositoryFake(this.transaccion);

  @override
  Future<List<TransaccionModel>> obtenerTransacciones(String usuarioId) async {
    return [transaccion];
  }

  @override
  Stream<List<TransaccionModel>> escucharTransacciones(String usuarioId) {
    return Stream.value([transaccion]);
  }

  @override
  Future<TransaccionModel?> obtenerTransaccionPorId(
    String transaccionId,
    String usuarioId,
  ) async {
    return transaccion.id == transaccionId ? transaccion : null;
  }

  @override
  Future<void> completarTransaccion(String transaccionId) async {
    transaccionCompletadaId = transaccionId;
  }

  @override
  Future<void> cancelarTransaccion(String transaccionId) async {
    transaccionCanceladaId = transaccionId;
  }
}

