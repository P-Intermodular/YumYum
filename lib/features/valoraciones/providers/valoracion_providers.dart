import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/valoracion_model.dart';
import 'valoracion_repository_provider.dart';

/// Comprueba si el usuario ya ha valorado una transacción concreta.
final valoracionUsuarioProvider =
    FutureProvider.family<ValoracionModel?, (String, String)>(
  (ref, params) async {
    final (transaccionId, valoradorId) = params;
    return ref
        .watch(valoracionRepositoryProvider)
        .obtenerValoracionUsuario(transaccionId, valoradorId);
  },
);

/// Lista las valoraciones recibidas por un usuario.
final valoracionesRecibidasProvider =
    FutureProvider.family<List<ValoracionModel>, String>(
  (ref, valoradoId) async {
    return ref
        .watch(valoracionRepositoryProvider)
        .obtenerValoracionesRecibidas(valoradoId);
  },
);
