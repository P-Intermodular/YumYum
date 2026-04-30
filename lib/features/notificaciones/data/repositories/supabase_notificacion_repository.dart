import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../domain/entities/notificacion_model.dart';
import '../../domain/repositories/notificacion_repository.dart';
import '../dtos/notificacion_dto.dart';

/// Implementación de [NotificacionRepository] con realtime de Supabase.
class SupabaseNotificacionRepository implements NotificacionRepository {
  final SupabaseClient _client;

  SupabaseNotificacionRepository(this._client);

  @override

  /// Escucha en tiempo real las notificaciones del usuario, ordenadas por
  /// fecha de creación descendente.
  Stream<List<NotificacionModel>> obtenerNotificaciones(
    String usuarioId,
  ) {
    return _client
        .from(TablasSupabase.notificaciones)
        .stream(primaryKey: ['id'])
        .eq('usuario_id', usuarioId)
        .order('creado_en', ascending: false)
        .map(
          (rows) => rows
              .cast<Map<String, dynamic>>()
              .map(NotificacionDto.desdeSupabase)
              .toList(),
        );
  }

  @override

  /// Marca como leídas todas las notificaciones pendientes del usuario.
  Future<void> marcarTodasLeidas(String usuarioId) async {
    await _client
        .from(TablasSupabase.notificaciones)
        .update({'leido_en': DateTime.now().toIso8601String()})
        .eq('usuario_id', usuarioId)
        .isFilter('leido_en', null);
  }
}
