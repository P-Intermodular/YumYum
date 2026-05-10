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
  final int cantidad;
  final int? cantidadOfrecida;

  /// URL pública de la primera imagen del plato. Permite a las pantallas que
  /// listan solicitudes pintar la card con la foto sin tener que ir al
  /// detalle del producto.
  final String urlImagenProducto;

  /// Precio unitario del plato (€) cuando es una oferta de venta. Útil en la
  /// card del listado para mostrar el precio antes de que exista transacción.
  final double? precioUnitario;

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
    this.cantidad = 1,
    this.cantidadOfrecida,
    this.urlImagenProducto = '',
    this.precioUnitario,
  });
}
