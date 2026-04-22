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

  factory TransaccionModel.desdePartes({
    required Map<String, dynamic> transaccion,
    required String tituloProducto,
    required String nombreContraparte,
  }) {
    return TransaccionModel(
      id: transaccion['id'] as String,
      tipo: transaccion['tipo'] as String? ?? 'venta',
      estado: transaccion['estado'] as String? ?? 'aceptada',
      tituloProducto: tituloProducto,
      nombreContraparte: nombreContraparte,
      total: _toDoubleOrNull(transaccion['total']),
      creadoEn: DateTime.tryParse(transaccion['creado_en']?.toString() ?? '') ??
          DateTime.now(),
      completadoEn:
          DateTime.tryParse(transaccion['completado_en']?.toString() ?? ''),
    );
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
