import '../entities/conversacion_model.dart';

/// Contrato de lectura y escritura para el chat interno de YumYum.
abstract class ChatRepository {
  /// Obtiene la lista de conversaciones en las que participa el usuario.
  Future<List<ConversacionModel>> obtenerChats(String usuarioId);

  /// Escucha en tiempo real la lista de conversaciones del usuario.
  Stream<List<ConversacionModel>> escucharChats(String usuarioId);

  /// Escucha en tiempo real los mensajes de una conversación.
  Stream<List<MensajeModel>> obtenerMensajes(String conversacionId);

  /// Inserta un nuevo mensaje en la conversación indicada.
  Future<void> enviarMensaje(String conversacionId, MensajeModel mensaje);

  /// Marca como leídos los mensajes recibidos en la conversación indicada.
  Future<void> marcarMensajesLeidos(String conversacionId, String usuarioId);
}
