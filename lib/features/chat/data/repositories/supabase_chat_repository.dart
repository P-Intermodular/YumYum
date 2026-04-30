import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../domain/entities/conversacion_model.dart';
import '../../domain/repositories/chat_repository.dart';
import '../dtos/conversacion_dto.dart';
import '../dtos/mensaje_dto.dart';

/// Implementación de [ChatRepository] apoyada en tablas y realtime de Supabase.
class SupabaseChatRepository implements ChatRepository {
  /// Select enriquecido para resolver la contraparte y el último mensaje.
  static const conversacionSelect = '''
    id,
    solicitante_id,
    propietario_id,
    creado_en,
    solicitante:perfiles!conversaciones_solicitante_id_fkey(
      id,
      nombre,
      url_avatar,
      valoracion_media,
      numero_valoraciones
    ),
    propietario:perfiles!conversaciones_propietario_id_fkey(
      id,
      nombre,
      url_avatar,
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

  /// Recupera las conversaciones donde participa el usuario.
  Future<List<ConversacionModel>> obtenerChats(String usuarioId) async {
    final rows = await _client
        .from(TablasSupabase.conversaciones)
        .select(conversacionSelect)
        .or('solicitante_id.eq.$usuarioId,propietario_id.eq.$usuarioId')
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
