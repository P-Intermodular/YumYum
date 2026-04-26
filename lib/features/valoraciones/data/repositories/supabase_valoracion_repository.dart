import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../domain/entities/valoracion_model.dart';
import '../../domain/repositories/valoracion_repository.dart';
import '../dtos/valoracion_dto.dart';

/// Implementación de [ValoracionRepository] apoyada en Supabase.
class SupabaseValoracionRepository implements ValoracionRepository {
  /// Select con join al perfil del valorador para mostrar nombre y avatar.
  static const _selectConValorador = '''
    *,
    valorador:valorador_id(nombre, url_avatar)
  ''';

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

  @override

  /// Devuelve la valoración del usuario para una transacción, si existe.
  Future<ValoracionModel?> obtenerValoracionUsuario(
    String transaccionId,
    String valoradorId,
  ) async {
    final row = await _client
        .from(TablasSupabase.valoraciones)
        .select(_selectConValorador)
        .eq('transaccion_id', transaccionId)
        .eq('valorador_id', valoradorId)
        .maybeSingle();

    if (row == null) return null;
    return ValoracionDto.desdeSupabase(row);
  }

  @override

  /// Lista las valoraciones recibidas por un usuario, ordenadas por fecha.
  Future<List<ValoracionModel>> obtenerValoracionesRecibidas(
    String valoradoId,
  ) async {
    final rows = await _client
        .from(TablasSupabase.valoraciones)
        .select(_selectConValorador)
        .eq('valorado_id', valoradoId)
        .order('creado_en', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map(ValoracionDto.desdeSupabase)
        .toList();
  }
}
