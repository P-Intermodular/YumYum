/// Representa una solicitud enviada o recibida sobre una oferta publicada.
class SolicitudOfertaModel {
  final String id;
  final String tipoSolicitud;
  final String estado;
  final String productoId;
  final String? productoOfrecidoId;
  final String tituloProducto;
  final String nombreContraparte;
  final String? mensaje;
  final DateTime creadoEn;
  final bool esEntrante;

  const SolicitudOfertaModel({
    required this.id,
    required this.tipoSolicitud,
    required this.estado,
    required this.productoId,
    this.productoOfrecidoId,
    required this.tituloProducto,
    required this.nombreContraparte,
    this.mensaje,
    required this.creadoEn,
    required this.esEntrante,
  });
}
