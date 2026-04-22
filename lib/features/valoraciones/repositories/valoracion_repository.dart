import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';

abstract class ValoracionRepository {
  Future<void> crearValoracion({
    required String transaccionId,
    required String valoradorId,
    required String valoradoId,
    String? productoValoradoId,
    required int puntuacion,
    String? comentario,
  });
}

final valoracionRepositoryProvider = Provider<ValoracionRepository>((ref) {
  return SupabaseValoracionRepository(ref.watch(supabaseClientProvider));
});

class SupabaseValoracionRepository implements ValoracionRepository {
  final SupabaseClient _client;

  SupabaseValoracionRepository(this._client);

  @override
  Future<void> crearValoracion({
    required String transaccionId,
    required String valoradorId,
    required String valoradoId,
    String? productoValoradoId,
    required int puntuacion,
    String? comentario,
  }) async {
    await _client.from('valoraciones').insert({
      'transaccion_id': transaccionId,
      'valorador_id': valoradorId,
      'valorado_id': valoradoId,
      'producto_valorado_id': productoValoradoId,
      'puntuacion': puntuacion,
      'comentario': comentario,
    });
  }
}
