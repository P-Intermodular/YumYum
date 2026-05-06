/// Entidad que representa una notificación recibida por el usuario.
class NotificacionModel {
  final String id;
  final String tipo;
  final String titulo;
  final String contenido;
  final Map<String, dynamic> datos;
  final DateTime? leidoEn;
  final DateTime creadoEn;

  const NotificacionModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.contenido,
    required this.datos,
    this.leidoEn,
    required this.creadoEn,
  });

  /// Indica si la notificación aún no ha sido leída.
  bool get noLeida => leidoEn == null;
}
