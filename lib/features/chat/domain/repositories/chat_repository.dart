import '../entities/conversacion_model.dart';

abstract class ChatRepository {
  Future<List<ConversacionModel>> obtenerChats(String usuarioId);
  Stream<List<MensajeModel>> obtenerMensajes(String conversacionId);
  Future<void> enviarMensaje(String conversacionId, MensajeModel mensaje);
}
