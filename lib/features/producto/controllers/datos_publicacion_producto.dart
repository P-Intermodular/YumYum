import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

/// Imagen elegida por el cocinero antes de publicar un producto. Se almacena
/// en memoria con sus bytes y extension hasta que el repositorio la sube a
/// Storage como parte del flujo de publicacion.
class ImagenSeleccionada {
  final Uint8List bytes;
  final String extension;

  const ImagenSeleccionada({required this.bytes, required this.extension});
}

/// Datos que la UI necesita reunir antes de publicar una oferta.
///
/// La [ubicacionExacta] es la coordenada real elegida por el usuario en el
/// mapa. La `ubicacionPublica` se calcula en el controlador como un
/// desplazamiento aleatorio sobre la exacta para preservar la privacidad del
/// punto de recogida hasta que se confirme una transaccion.
class DatosPublicacionProducto {
  final String titulo;
  final String descripcion;
  final String tipo;
  final double? precio;
  final String categoria;
  final List<String> etiquetas;
  final List<String> alergenos;
  final bool sinAlergenosDeclarados;
  final int raciones;
  /// Imagenes elegidas en orden (la primera es la portada).
  final List<ImagenSeleccionada> imagenes;
  final LatLng ubicacionExacta;

  const DatosPublicacionProducto({
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    this.precio,
    required this.categoria,
    this.etiquetas = const [],
    this.alergenos = const [],
    this.sinAlergenosDeclarados = false,
    this.raciones = 1,
    this.imagenes = const [],
    required this.ubicacionExacta,
  });
}
