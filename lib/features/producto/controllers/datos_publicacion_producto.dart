import 'dart:typed_data';

class DatosPublicacionProducto {
  final String titulo;
  final String descripcion;
  final String tipo;
  final double? precio;
  final Uint8List? bytesImagen;
  final String extensionImagen;

  const DatosPublicacionProducto({
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    this.precio,
    this.bytesImagen,
    required this.extensionImagen,
  });
}
