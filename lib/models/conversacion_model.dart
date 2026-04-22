import 'usuario_model.dart';

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

  factory MensajeModel.desdeSupabase(Map<String, dynamic> json) {
    return MensajeModel(
      id: json['id'] as String,
      texto: json['contenido'] as String? ?? '',
      remitenteId: json['remitente_id'] as String,
      creadoEn: DateTime.tryParse(json['creado_en']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> aInsercionMensaje(String conversacionId) {
    return {
      'conversacion_id': conversacionId,
      'remitente_id': remitenteId,
      'contenido': texto,
    };
  }
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
