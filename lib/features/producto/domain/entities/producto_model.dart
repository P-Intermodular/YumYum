import 'package:latlong2/latlong.dart';

import '../../../auth/domain/entities/usuario_model.dart';
import '../../../../core/constants/categorias_producto.dart';

/// Entidad de dominio que representa una oferta publicada en YumYum.
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
  final double? distanciaKm;
  final String categoria;
  final List<String> etiquetas;
  final List<String> alergenos;
  final bool sinAlergenosDeclarados;
  final int racionesTotales;
  final int racionesDisponibles;
  // Coordenadas aproximadas visibles en feed y mapa. La ubicacion exacta solo
  // se obtiene mediante la RPC `obtener_ubicacion_exacta_producto` para los
  // participantes autorizados de una transaccion.
  final LatLng ubicacionPublica;

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
    this.distanciaKm,
    this.categoria = CategoriaProducto.otros,
    this.etiquetas = const [],
    this.alergenos = const [],
    this.sinAlergenosDeclarados = false,
    this.racionesTotales = 1,
    this.racionesDisponibles = 1,
    required this.ubicacionPublica,
  });

  /// Devuelve una copia parcial del producto manteniendo el resto de campos.
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
    double? distanciaKm,
    String? categoria,
    List<String>? etiquetas,
    List<String>? alergenos,
    bool? sinAlergenosDeclarados,
    int? racionesTotales,
    int? racionesDisponibles,
    LatLng? ubicacionPublica,
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
      distanciaKm: distanciaKm ?? this.distanciaKm,
      categoria: categoria ?? this.categoria,
      etiquetas: etiquetas ?? this.etiquetas,
      alergenos: alergenos ?? this.alergenos,
      sinAlergenosDeclarados:
          sinAlergenosDeclarados ?? this.sinAlergenosDeclarados,
      racionesTotales: racionesTotales ?? this.racionesTotales,
      racionesDisponibles: racionesDisponibles ?? this.racionesDisponibles,
      ubicacionPublica: ubicacionPublica ?? this.ubicacionPublica,
    );
  }
}
