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

  factory SolicitudOfertaModel.desdePartes({
    required Map<String, dynamic> solicitud,
    required String tituloProducto,
    required String nombreContraparte,
    required bool esEntrante,
  }) {
    return SolicitudOfertaModel(
      id: solicitud['id'] as String,
      tipoSolicitud: solicitud['tipo_solicitud'] as String? ?? 'venta',
      estado: solicitud['estado'] as String? ?? 'pendiente',
      productoId: solicitud['producto_id'] as String,
      productoOfrecidoId: solicitud['producto_ofrecido_id'] as String?,
      tituloProducto: tituloProducto,
      nombreContraparte: nombreContraparte,
      mensaje: solicitud['mensaje'] as String?,
      creadoEn: DateTime.tryParse(solicitud['creado_en']?.toString() ?? '') ??
          DateTime.now(),
      esEntrante: esEntrante,
    );
  }
}
