import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

/// Imagen elegida por el cocinero en el formulario de publicar/editar.
///
/// Tiene dos modalidades:
///  - **Nueva**: bytes + extension (el repositorio la sube a Storage al
///    guardar). El constructor por defecto produce una imagen nueva.
///  - **Existente**: ya está en Storage; conocemos su `id` en la tabla
///    `imagenes_producto`, su `urlRemota` para pintarla en el grid y su
///    `rutaStorage` para poder borrar el blob cuando el usuario la quita.
class ImagenSeleccionada {
  final Uint8List bytes;
  final String extension;
  final String? id;
  final String? urlRemota;
  final String? rutaStorage;

  /// Imagen recién seleccionada por el usuario.
  const ImagenSeleccionada({
    required this.bytes,
    required this.extension,
  })  : id = null,
        urlRemota = null,
        rutaStorage = null;

  /// Imagen ya persistida que se carga al entrar en modo edición.
  ImagenSeleccionada.existente({
    required String this.id,
    required String this.urlRemota,
    required String this.rutaStorage,
  })  : bytes = Uint8List(0),
        extension = '';

  bool get esExistente => id != null;
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
