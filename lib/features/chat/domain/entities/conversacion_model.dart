import '../../../auth/domain/entities/usuario_model.dart';

/// Mensaje individual intercambiado dentro de una conversación.
class MensajeModel {
  final String id;
  final String texto;
  final String remitenteId;
  final DateTime creadoEn;

  /// Momento en el que la otra parte marcó el mensaje como leído. Sirve para
  /// pintar el doble-tick (estilo WhatsApp) en mensajes propios cuando el
  /// destinatario los ha visto.
  final DateTime? leidoEn;

  const MensajeModel({
    required this.id,
    required this.texto,
    required this.remitenteId,
    required this.creadoEn,
    this.leidoEn,
  });
}

/// Vista ligera del producto que originó la conversación.
///
/// No reutilizamos `ProductoModel` para evitar arrastrar coordenadas,
/// distancia y el `propietario` completo; aquí solo necesitamos lo que se
/// pinta en la lista de chats y el banner del chat individual.
class ProductoEnChat {
  final String id;
  final String titulo;
  final String urlImagen;
  final double? precio;
  final String tipoOferta;

  const ProductoEnChat({
    required this.id,
    required this.titulo,
    required this.urlImagen,
    required this.tipoOferta,
    this.precio,
  });
}

/// Conversación visible en la bandeja de chats del usuario.
class ConversacionModel {
  final String id;
  final UsuarioModel participante;
  final ProductoEnChat? producto;
  final MensajeModel? ultimoMensaje;
  final int mensajesNoLeidos;

  /// Id de la solicitud asociada al chat. Existe siempre (la conversación se
  /// crea junto con la solicitud), pero se deja anulable para tolerar datos
  /// antiguos sin solicitud.
  final String? solicitudId;

  /// Estado actual de la solicitud (pendiente / aceptada / denegada / ...).
  /// Permite decidir el destino del banner del chat.
  final String? estadoSolicitud;

  /// Id de la transacción cuando la solicitud ya fue aceptada. Null mientras
  /// la solicitud está pendiente o si fue denegada/cancelada.
  final String? transaccionId;

  /// Estado de la transacción cuando existe (pendiente / aceptada / completada
  /// / cancelada / reportada). Permite filtrar la bandeja por chats con
  /// pedido en curso.
  final String? estadoTransaccion;

  const ConversacionModel({
    required this.id,
    required this.participante,
    this.producto,
    this.ultimoMensaje,
    this.mensajesNoLeidos = 0,
    this.solicitudId,
    this.estadoSolicitud,
    this.transaccionId,
    this.estadoTransaccion,
  });
}
