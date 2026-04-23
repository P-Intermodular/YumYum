import '../../../auth/domain/entities/usuario_model.dart';

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
