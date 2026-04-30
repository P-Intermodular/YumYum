import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumyum/core/constants/estados_app.dart';
import 'package:yumyum/core/supabase/supabase_client_provider.dart';
import 'package:yumyum/features/auth/controllers/auth_controller.dart';
import 'package:yumyum/features/auth/providers/auth_repository_provider.dart';
import 'package:yumyum/features/pedidos/domain/entities/transaccion_model.dart';
import 'package:yumyum/features/valoraciones/controllers/valoracion_controller.dart';
import 'package:yumyum/features/valoraciones/domain/entities/valoracion_model.dart';
import 'package:yumyum/features/valoraciones/domain/repositories/valoracion_repository.dart';
import 'package:yumyum/features/valoraciones/providers/valoracion_repository_provider.dart';

import '../../../helpers/auth_test_utils.dart';

void main() {
  group('ValoracionController', () {
    test('envia valoracion calculando valorado y producto valorado', () async {
      final repository = _ValoracionRepositoryFake();
      final container = ProviderContainer(
        overrides: [
          autenticacionRepositoryProvider.overrideWithValue(
            AuthRepositoryFake(usuarioActual: usuarioTest()),
          ),
          supabaseClientProvider.overrideWithValue(supabaseTestClient()),
          valoracionRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      container.read(autenticacionProvider);
      await container.pump();

      await container
          .read(valoracionControllerProvider.notifier)
          .enviarValoracion(
            transaccion: _transaccion(),
            puntuacion: 5,
            comentario: '   ',
          );

      expect(repository.transaccionId, 'transaccion-1');
      expect(repository.valoradorId, 'usuario-1');
      expect(repository.valoradoId, 'usuario-2');
      expect(repository.productoValoradoId, 'producto-1');
      expect(repository.puntuacion, 5);
      expect(repository.comentario, isNull);
      expect(container.read(valoracionControllerProvider).hasError, false);
    });
  });
}

TransaccionModel _transaccion() {
  return TransaccionModel(
    id: 'transaccion-1',
    tipo: TipoOferta.intercambio,
    estado: EstadoTransaccion.completada,
    productoId: 'producto-1',
    productoOfrecidoId: 'producto-2',
    solicitanteId: 'usuario-1',
    propietarioId: 'usuario-2',
    tituloProducto: 'Tarta',
    nombreContraparte: 'Luis',
    creadoEn: DateTime(2026),
  );
}

class _ValoracionRepositoryFake implements ValoracionRepository {
  String? transaccionId;
  String? valoradorId;
  String? valoradoId;
  String? productoValoradoId;
  int? puntuacion;
  String? comentario;

  @override
  Future<void> crearValoracion({
    required String transaccionId,
    required String valoradorId,
    required String valoradoId,
    String? productoValoradoId,
    required int puntuacion,
    String? comentario,
  }) async {
    this.transaccionId = transaccionId;
    this.valoradorId = valoradorId;
    this.valoradoId = valoradoId;
    this.productoValoradoId = productoValoradoId;
    this.puntuacion = puntuacion;
    this.comentario = comentario;
  }

  @override
  Future<ValoracionModel?> obtenerValoracionUsuario(
    String transaccionId,
    String valoradorId,
  ) async {
    return null;
  }

  @override
  Future<List<ValoracionModel>> obtenerValoracionesRecibidas(
    String valoradoId,
  ) async {
    return [];
  }
}
