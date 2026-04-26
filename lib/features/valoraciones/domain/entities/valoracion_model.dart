/// Representa una valoración emitida sobre una transacción completada.
class ValoracionModel {
  final String id;
  final String transaccionId;
  final String valoradorId;
  final String valoradoId;
  final int puntuacion;
  final String? comentario;
  final DateTime creadoEn;
  final String nombreValorador;
  final String urlAvatarValorador;

  const ValoracionModel({
    required this.id,
    required this.transaccionId,
    required this.valoradorId,
    required this.valoradoId,
    required this.puntuacion,
    this.comentario,
    required this.creadoEn,
    this.nombreValorador = 'Usuario YumYum',
    this.urlAvatarValorador = '',
  });
}
