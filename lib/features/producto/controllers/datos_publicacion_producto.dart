import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

/// Datos que la UI necesita reunir antes de publicar una oferta.
///
/// La [ubicacionExacta] es la coordenada real elegida por el usuario en el
/// mapa. La [ubicacionPublica] se calcula en el controlador como un
/// desplazamiento aleatorio sobre la exacta para preservar la privacidad del
/// punto de recogida hasta que se confirme una transaccion.
class DatosPublicacionProducto {
  final String titulo;
  final String descripcion;
  final String tipo;
  final double? precio;
  final Uint8List? bytesImagen;
  final String extensionImagen;
  final LatLng ubicacionExacta;

  const DatosPublicacionProducto({
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    this.precio,
    this.bytesImagen,
    required this.extensionImagen,
    required this.ubicacionExacta,
  });
}
