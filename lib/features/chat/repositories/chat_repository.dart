import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../../models/conversacion_model.dart';
import '../../../models/usuario_model.dart';

abstract class ChatRepository {
  Future<List<ConversacionModel>> obtenerChats(String usuarioId);
  Stream<List<MensajeModel>> obtenerMensajes(String conversacionId);
  Future<void> enviarMensaje(String conversacionId, MensajeModel mensaje);
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SupabaseChatRepository(ref.watch(supabaseClientProvider));
});

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _client;

  SupabaseChatRepository(this._client);

  @override
  Future<List<ConversacionModel>> obtenerChats(String usuarioId) async {
    final rows = await _client
        .from('conversaciones')
        .select()
        .or('comprador_id.eq.$usuarioId,vendedor_id.eq.$usuarioId')
        .order('creado_en', ascending: false);

    final conversaciones = <ConversacionModel>[];
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final participanteId = row['comprador_id'] == usuarioId
          ? row['vendedor_id'] as String
          : row['comprador_id'] as String;

      final participante = await _obtenerPerfil(participanteId);
      final ultimoMensaje = await _obtenerUltimoMensaje(row['id'] as String);

      conversaciones.add(
        ConversacionModel(
          id: row['id'] as String,
          participante: participante,
          ultimoMensaje: ultimoMensaje,
        ),
      );
    }

    return conversaciones;
  }

  @override
  Stream<List<MensajeModel>> obtenerMensajes(String conversacionId) {
    return _client
        .from('mensajes')
        .stream(primaryKey: ['id'])
        .eq('conversacion_id', conversacionId)
        .order('creado_en')
        .map(
          (rows) => rows
              .cast<Map<String, dynamic>>()
              .map(MensajeModel.desdeSupabase)
              .toList(),
        );
  }

  @override
  Future<void> enviarMensaje(
      String conversacionId, MensajeModel mensaje) async {
    await _client
        .from('mensajes')
        .insert(mensaje.aInsercionMensaje(conversacionId));
  }

  Future<UsuarioModel> _obtenerPerfil(String usuarioId) async {
    final row =
        await _client.from('perfiles').select().eq('id', usuarioId).single();

    return UsuarioModel.desdePerfil(row);
  }

  Future<MensajeModel?> _obtenerUltimoMensaje(String conversacionId) async {
    final rows = await _client
        .from('mensajes')
        .select()
        .eq('conversacion_id', conversacionId)
        .order('creado_en', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return MensajeModel.desdeSupabase(rows.cast<Map<String, dynamic>>().first);
  }
}
