import 'package:latlong2/latlong.dart';

import 'usuario_model.dart';

class ProductoModel {
  final String id;
  final String titulo;
  final String descripcion;
  final String urlImagen;
  final UsuarioModel propietario;
  final DateTime creadoEn;
  final String tipo;
  final String estado;
  final double? precio;
  final LatLng ubicacion;

  const ProductoModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.urlImagen,
    required this.propietario,
    required this.creadoEn,
    required this.tipo,
    this.estado = 'disponible',
    this.precio,
    required this.ubicacion,
  });

  factory ProductoModel.desdeSupabase(Map<String, dynamic> json) {
    final propietarioJson = json['perfiles'] as Map<String, dynamic>?;
    final imagenes = json['imagenes_producto'] as List<dynamic>? ?? const [];
    final imagenesOrdenadas = imagenes.cast<Map<String, dynamic>>().toList()
      ..sort((a, b) =>
          (a['posicion'] as int? ?? 0).compareTo(b['posicion'] as int? ?? 0));
    final urlImagen = imagenesOrdenadas.isEmpty
        ? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500'
        : imagenesOrdenadas.first['url_publica'] as String? ??
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500';

    return ProductoModel(
      id: json['id'] as String,
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      urlImagen: urlImagen,
      propietario: propietarioJson == null
          ? UsuarioModel(
              id: json['propietario_id'] as String,
              nombre: 'Usuario YumYum',
              correo: '',
              urlImagenPerfil:
                  'https://i.pravatar.cc/150?u=${json['propietario_id']}',
            )
          : UsuarioModel.desdePerfil(propietarioJson),
      creadoEn: DateTime.tryParse(json['creado_en']?.toString() ?? '') ??
          DateTime.now(),
      tipo: json['tipo_oferta'] as String? ?? 'intercambio',
      estado: json['estado'] as String? ?? 'disponible',
      precio: _toDoubleOrNull(json['precio']),
      ubicacion: LatLng(
        _toDouble(json['latitud_publica']),
        _toDouble(json['longitud_publica']),
      ),
    );
  }

  Map<String, dynamic> aInsercionProducto() {
    return {
      'propietario_id': propietario.id,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo_oferta': tipo,
      'precio': tipo == 'venta' ? precio : null,
      'estado': estado,
      'latitud_publica': ubicacion.latitude,
      'longitud_publica': ubicacion.longitude,
      'latitud_exacta': ubicacion.latitude,
      'longitud_exacta': ubicacion.longitude,
    };
  }

  ProductoModel copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    String? urlImagen,
    UsuarioModel? propietario,
    DateTime? creadoEn,
    String? tipo,
    String? estado,
    double? precio,
    LatLng? ubicacion,
  }) {
    return ProductoModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      urlImagen: urlImagen ?? this.urlImagen,
      propietario: propietario ?? this.propietario,
      creadoEn: creadoEn ?? this.creadoEn,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      precio: precio ?? this.precio,
      ubicacion: ubicacion ?? this.ubicacion,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
