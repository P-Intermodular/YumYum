/// Resume una transacción visible en el panel de pedidos.
class TransaccionModel {
  final String id;
  final String tipo;
  final String estado;
  final String productoId;
  final String? productoOfrecidoId;
  final String solicitanteId;
  final String propietarioId;
  final String tituloProducto;
  final String nombreContraparte;
  final String urlAvatarContraparte;
  final double valoracionMediaContraparte;
  final int numeroValoracionesContraparte;
  final double? total;
  final DateTime creadoEn;
  final DateTime? completadoEn;
  final int cantidad;
  final int? cantidadOfrecida;

  /// Id de la solicitud que dio origen a esta transacción. Permite a la
  /// pantalla de listado deduplicar contra las solicitudes (cuando una
  /// solicitud está aceptada, se pinta la transacción y no la solicitud).
  final String? solicitudId;

  /// URL pública de la primera imagen del plato. Para que el listado pueda
  /// pintar la card sin pasar por el detalle del producto.
  final String urlImagenProducto;

  /// Precio unitario del plato (€). Útil cuando la transacción es de
  /// intercambio y `total` es null, pero queremos seguir mostrando el precio
  /// de referencia del plato en la card.
  final double? precioUnitario;

  const TransaccionModel({
    required this.id,
    required this.tipo,
    required this.estado,
    required this.productoId,
    this.productoOfrecidoId,
    required this.solicitanteId,
    required this.propietarioId,
    required this.tituloProducto,
    required this.nombreContraparte,
    this.urlAvatarContraparte = '',
    this.valoracionMediaContraparte = 0,
    this.numeroValoracionesContraparte = 0,
    this.total,
    required this.creadoEn,
    this.completadoEn,
    this.cantidad = 1,
    this.cantidadOfrecida,
    this.solicitudId,
    this.urlImagenProducto = '',
    this.precioUnitario,
  });

  /// Devuelve el ID de la contraparte en la transacción.
  String contraparte(String usuarioId) =>
      usuarioId == solicitanteId ? propietarioId : solicitanteId;
}
