class TransaccionModel {
  final String id;
  final String tipo;
  final String estado;
  final String tituloProducto;
  final String nombreContraparte;
  final double? total;
  final DateTime creadoEn;
  final DateTime? completadoEn;

  const TransaccionModel({
    required this.id,
    required this.tipo,
    required this.estado,
    required this.tituloProducto,
    required this.nombreContraparte,
    this.total,
    required this.creadoEn,
    this.completadoEn,
  });
}
