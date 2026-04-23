import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../domain/repositories/valoracion_repository.dart';

/// Implementación de [ValoracionRepository] apoyada en Supabase.
class SupabaseValoracionRepository implements ValoracionRepository {
  final SupabaseClient _client;

  SupabaseValoracionRepository(this._client);

  @override

  /// Inserta la valoración y delega la agregación al trigger de la base de datos.
  Future<void> crearValoracion({
    required String transaccionId,
    required String valoradorId,
    required String valoradoId,
    String? productoValoradoId,
    required int puntuacion,
    String? comentario,
  }) async {
    await _client.from(TablasSupabase.valoraciones).insert({
      'transaccion_id': transaccionId,
      'valorador_id': valoradorId,
      'valorado_id': valoradoId,
      'producto_valorado_id': productoValoradoId,
      'puntuacion': puntuacion,
      'comentario': comentario,
    });
  }
}
