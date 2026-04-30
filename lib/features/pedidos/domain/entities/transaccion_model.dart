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
  });

  /// Devuelve el ID de la contraparte en la transacción.
  String contraparte(String usuarioId) =>
      usuarioId == solicitanteId ? propietarioId : solicitanteId;
}
