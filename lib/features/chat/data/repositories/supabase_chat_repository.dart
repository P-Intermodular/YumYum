import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../domain/entities/conversacion_model.dart';
import '../../domain/repositories/chat_repository.dart';
import '../dtos/conversacion_dto.dart';
import '../dtos/mensaje_dto.dart';

/// Implementación de [ChatRepository] apoyada en tablas y realtime de Supabase.
class SupabaseChatRepository implements ChatRepository {
  /// Select enriquecido para resolver la contraparte y el último mensaje.
  static const _conversacionSelect = '''
    id,
    comprador_id,
    vendedor_id,
    creado_en,
    comprador:comprador_id(
      id,
      nombre,
      email,
      url_avatar,
      ciudad,
      preferencias,
      certificacion_sanitaria,
      es_moderador,
      valoracion_media,
      numero_valoraciones
    ),
    vendedor:vendedor_id(
      id,
      nombre,
      email,
      url_avatar,
      ciudad,
      preferencias,
      certificacion_sanitaria,
      es_moderador,
      valoracion_media,
      numero_valoraciones
    ),
    mensajes(
      id,
      contenido,
      remitente_id,
      creado_en
    )
  ''';

  final SupabaseClient _client;

  SupabaseChatRepository(this._client);

  @override

  /// Recupera las conversaciones donde el usuario participa como comprador o vendedor.
  Future<List<ConversacionModel>> obtenerChats(String usuarioId) async {
    final rows = await _client
        .from(TablasSupabase.conversaciones)
        .select(_conversacionSelect)
        .or('comprador_id.eq.$usuarioId,vendedor_id.eq.$usuarioId')
        .order('creado_en', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => ConversacionDto.desdeSupabase(row, usuarioId))
        .toList();
  }

  @override

  /// Escucha los mensajes ordenados cronológicamente para pintar el chat.
  Stream<List<MensajeModel>> obtenerMensajes(String conversacionId) {
    return _client
        .from(TablasSupabase.mensajes)
        .stream(primaryKey: ['id'])
        .eq('conversacion_id', conversacionId)
        .order('creado_en')
        .map(
          (rows) => rows
              .cast<Map<String, dynamic>>()
              .map(MensajeDto.desdeSupabase)
              .toList(),
        );
  }

  @override

  /// Inserta un nuevo mensaje en la conversación indicada.
  Future<void> enviarMensaje(
    String conversacionId,
    MensajeModel mensaje,
  ) async {
    await _client
        .from(TablasSupabase.mensajes)
        .insert(MensajeDto.aInsercion(mensaje, conversacionId));
  }
}
