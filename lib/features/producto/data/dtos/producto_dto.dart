import 'package:latlong2/latlong.dart';

import '../../../../core/constants/estados_app.dart';
import '../../../auth/data/dtos/usuario_dto.dart';
import '../../../auth/domain/entities/usuario_model.dart';
import '../../domain/entities/producto_model.dart';

abstract final class ProductoDto {
  static ProductoModel desdeSupabase(Map<String, dynamic> json) {
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
          : UsuarioDto.desdePerfil(propietarioJson),
      creadoEn: DateTime.tryParse(json['creado_en']?.toString() ?? '') ??
          DateTime.now(),
      tipo: json['tipo_oferta'] as String? ?? TipoOferta.intercambio,
      estado: json['estado'] as String? ?? EstadoProducto.disponible,
      precio: _toDoubleOrNull(json['precio']),
      ubicacion: LatLng(
        _toDouble(json['latitud_publica']),
        _toDouble(json['longitud_publica']),
      ),
    );
  }

  static Map<String, dynamic> aInsercion(ProductoModel producto) {
    return {
      'propietario_id': producto.propietario.id,
      'titulo': producto.titulo,
      'descripcion': producto.descripcion,
      'tipo_oferta': producto.tipo,
      'precio': producto.tipo == TipoOferta.venta ? producto.precio : null,
      'estado': producto.estado,
      'latitud_publica': producto.ubicacion.latitude,
      'longitud_publica': producto.ubicacion.longitude,
      'latitud_exacta': producto.ubicacion.latitude,
      'longitud_exacta': producto.ubicacion.longitude,
    };
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
