import '../../../auth/domain/entities/usuario_model.dart';

/// Mensaje individual intercambiado dentro de una conversación.
class MensajeModel {
  final String id;
  final String texto;
  final String remitenteId;
  final DateTime creadoEn;

  const MensajeModel({
    required this.id,
    required this.texto,
    required this.remitenteId,
    required this.creadoEn,
  });
}

/// Conversación visible en la bandeja de chats del usuario.
class ConversacionModel {
  final String id;
  final UsuarioModel participante;
  final MensajeModel? ultimoMensaje;
  final int mensajesNoLeidos;

  const ConversacionModel({
    required this.id,
    required this.participante,
    this.ultimoMensaje,
    this.mensajesNoLeidos = 0,
  });
}
