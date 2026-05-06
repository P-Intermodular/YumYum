import 'package:latlong2/latlong.dart';

import '../../../../core/constants/categorias_producto.dart';
import '../../../../core/constants/estados_app.dart';
import '../../../auth/data/dtos/usuario_dto.dart';
import '../../../auth/domain/entities/usuario_model.dart';
import '../../domain/entities/producto_model.dart';

/// Traduce filas de Supabase al modelo de dominio [ProductoModel].
abstract final class ProductoDto {
  /// Placeholder de portada cuando un producto todavia no tiene imagenes
  /// subidas a Storage. Mantiene el feed renderizable con una imagen
  /// reconocible mientras el cocinero termina la publicacion.
  static const _portadaPorDefecto =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500';

  /// Convierte una fila enriquecida con relaciones en una entidad de producto.
  static ProductoModel desdeSupabase(Map<String, dynamic> json) {
    final propietarioJson = json['perfiles'] as Map<String, dynamic>?;
    final imagenes = json['imagenes_producto'] as List<dynamic>? ?? const [];
    final imagenesOrdenadas = imagenes.cast<Map<String, dynamic>>().toList()
      ..sort((a, b) =>
          (a['posicion'] as int? ?? 0).compareTo(b['posicion'] as int? ?? 0));
    final urlsImagenes = imagenesOrdenadas
        .map((m) => m['url_publica'] as String?)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    // El feed siempre necesita una portada visible, aunque la oferta todavia no
    // tenga ficheros subidos.
    final listaFinal = urlsImagenes.isEmpty
        ? const <String>[_portadaPorDefecto]
        : urlsImagenes;

    return ProductoModel(
      id: json['id'] as String,
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      urlsImagenes: listaFinal,
      propietario: propietarioJson == null
          ? UsuarioModel(
              id: json['propietario_id'] as String,
              nombre: 'Usuario YumYum',
              correo: '',
              urlImagenPerfil: '',
            )
          : UsuarioDto.desdePerfil(propietarioJson),
      creadoEn: DateTime.tryParse(json['creado_en']?.toString() ?? '') ??
          DateTime.now(),
      tipo: json['tipo_oferta'] as String? ?? TipoOferta.intercambio,
      estado: json['estado'] as String? ?? EstadoProducto.disponible,
      precio: _toDoubleOrNull(json['precio']),
      distanciaKm: _toDoubleOrNull(json['distancia_km']),
      categoria:
          (json['categoria'] as String?) ?? CategoriaProducto.otros,
      etiquetas: _toStringList(json['etiquetas']),
      alergenos: _toStringList(json['alergenos']),
      sinAlergenosDeclarados:
          json['sin_alergenos_declarados'] as bool? ?? false,
      racionesTotales: json['raciones_totales'] as int? ?? 1,
      racionesDisponibles: json['raciones_disponibles'] as int? ?? 1,
      ubicacionPublica: LatLng(
        _toDouble(json['latitud_publica']),
        _toDouble(json['longitud_publica']),
      ),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  /// Prepara el payload compatible con la tabla `productos`.
  ///
  /// La ubicacion publica del producto es la que viaja en el feed y en el mapa,
  /// mientras que la exacta solo se entrega a participantes de la transaccion
  /// a traves de `obtener_ubicacion_exacta_producto`.
  static Map<String, dynamic> aInsercion(
    ProductoModel producto, {
    required LatLng ubicacionExacta,
  }) {
    return {
      'propietario_id': producto.propietario.id,
      'titulo': producto.titulo,
      'descripcion': producto.descripcion,
      'tipo_oferta': producto.tipo,
      'precio': producto.tipo == TipoOferta.venta ? producto.precio : null,
      'estado': producto.estado,
      'categoria': producto.categoria,
      'etiquetas': producto.etiquetas,
      'alergenos': producto.alergenos,
      'sin_alergenos_declarados': producto.sinAlergenosDeclarados,
      'raciones_totales': producto.racionesTotales,
      'raciones_disponibles': producto.racionesDisponibles,
      'latitud_publica': producto.ubicacionPublica.latitude,
      'longitud_publica': producto.ubicacionPublica.longitude,
      'latitud_exacta': ubicacionExacta.latitude,
      'longitud_exacta': ubicacionExacta.longitude,
    };
  }

  /// Normaliza valores numéricos obligatorios procedentes de la base de datos.
  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Normaliza valores numéricos opcionales como el precio.
  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
