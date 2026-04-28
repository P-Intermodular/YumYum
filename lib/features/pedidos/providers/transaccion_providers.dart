import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../domain/entities/transaccion_model.dart';
import 'transaccion_repository_provider.dart';

/// Carga el detalle de una transacción concreta a partir de su identificador.
final transaccionDetalleProvider =
    FutureProvider.autoDispose.family<TransaccionModel?, String>(
  (ref, transaccionId) async {
    final usuario = ref.watch(autenticacionProvider).value;
    if (usuario == null) return null;

    return ref
        .watch(transaccionRepositoryProvider)
        .obtenerTransaccionPorId(transaccionId, usuario.id);
  },
);
