import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../domain/entities/conversacion_model.dart';
import '../../domain/repositories/chat_repository.dart';
import '../dtos/conversacion_dto.dart';
import '../dtos/mensaje_dto.dart';

/// Implementación de [ChatRepository] apoyada en tablas y realtime de Supabase.
class SupabaseChatRepository implements ChatRepository {
  /// Select enriquecido para resolver la contraparte, el plato negociado y
  /// el último mensaje de la conversación.
  static const conversacionSelect = '''
    id,
    solicitud_id,
    solicitante_id,
    propietario_id,
    producto_id,
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
    producto:productos!conversaciones_producto_id_fkey(
      id,
      titulo,
      precio,
      tipo_oferta,
      imagenes_producto(
        url_publica,
        posicion
      )
    ),
    solicitud:solicitudes_oferta!conversaciones_solicitud_id_fkey(
      id,
      estado,
      transaccion:transacciones!transacciones_solicitud_id_fkey(id, estado)
    ),
    mensajes(
      id,
      contenido,
      remitente_id,
      creado_en,
      leido_en
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

  /// Escucha en tiempo real la lista de conversaciones del usuario.
  Stream<List<ConversacionModel>> escucharChats(String usuarioId) async* {
    yield await obtenerChats(usuarioId);

    final ctrl = StreamController<void>();
    final channel = _client
        .channel('chats-$usuarioId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: TablasSupabase.conversaciones,
          callback: (_) => ctrl.add(null),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: TablasSupabase.mensajes,
          callback: (_) => ctrl.add(null),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: TablasSupabase.mensajes,
          callback: (_) => ctrl.add(null),
        )
        // Cambios en estado de la solicitud (aceptar/denegar/cancelar)
        // re-disparan el fetch para que el banner del chat refleje a dónde
        // navegar y cómo etiquetar el pedido.
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: TablasSupabase.solicitudesOferta,
          callback: (_) => ctrl.add(null),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: TablasSupabase.transacciones,
          callback: (_) => ctrl.add(null),
        )
        .subscribe();

    try {
      await for (final _ in ctrl.stream) {
        yield await obtenerChats(usuarioId);
      }
    } finally {
      await _client.removeChannel(channel);
      await ctrl.close();
    }
  }

  @override

  /// Escucha los mensajes ordenados cronológicamente para pintar el chat.
  ///
  /// `ascending: true` es OBLIGATORIO: a diferencia de `.from().select().order()`
  /// (que por defecto es ASC), el `.order()` del SupabaseStreamBuilder
  /// defaultea a DESC. Sin este flag los mensajes llegarian de nuevo a viejo
  /// y el chat pintaria los nuevos en la parte superior en vez de la inferior.
  Stream<List<MensajeModel>> obtenerMensajes(String conversacionId) {
    return _client
        .from(TablasSupabase.mensajes)
        .stream(primaryKey: ['id'])
        .eq('conversacion_id', conversacionId)
        .order('creado_en', ascending: true)
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

  @override

  /// Marca como leídos todos los mensajes recibidos por [usuarioId] en la
  /// conversación indicada. Solo afecta a los mensajes ajenos que aún no
  /// tienen `leido_en`.
  Future<void> marcarMensajesLeidos(
    String conversacionId,
    String usuarioId,
  ) async {
    await _client
        .from(TablasSupabase.mensajes)
        .update({'leido_en': DateTime.now().toIso8601String()})
        .eq('conversacion_id', conversacionId)
        .neq('remitente_id', usuarioId)
        .isFilter('leido_en', null);
  }
}
