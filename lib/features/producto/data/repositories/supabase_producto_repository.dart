import 'dart:typed_data';

import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/estados_app.dart';
import '../../../../core/constants/supabase_names.dart';
import '../../controllers/datos_publicacion_producto.dart';
import '../../domain/repositories/producto_repository.dart';
import '../../domain/entities/producto_model.dart';
import '../dtos/producto_dto.dart';

/// Implementación de [ProductoRepository] respaldada por Supabase.
class SupabaseProductoRepository implements ProductoRepository {
  /// Select común que trae producto, perfil del propietario e imágenes.
  static const productoSelect = '''
    id,
    propietario_id,
    titulo,
    descripcion,
    tipo_oferta,
    precio,
    estado,
    categoria,
    etiquetas,
    alergenos,
    sin_alergenos_declarados,
    raciones_totales,
    raciones_disponibles,
    latitud_publica,
    longitud_publica,
    creado_en,
    perfiles:perfiles!productos_propietario_id_fkey(
      id,
      nombre,
      url_avatar,
      valoracion_media,
      numero_valoraciones
    ),
    imagenes_producto(
      url_publica,
      posicion
    )
  ''';

  final SupabaseClient _client;

  SupabaseProductoRepository(this._client);

  @override

  /// Recupera las ofertas publicadas con estado disponible.
  Future<List<ProductoModel>> obtenerProductos() async {
    final rows = await _client
        .from(TablasSupabase.productos)
        .select(productoSelect)
        .eq('estado', EstadoProducto.disponible)
        .order('creado_en', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map(ProductoDto.desdeSupabase)
        .toList();
  }

  @override

  /// Recupera las ofertas disponibles ordenadas por distancia al usuario.
  Future<List<ProductoModel>> obtenerProductosCercanos({
    required double latitud,
    required double longitud,
    double radioKm = 10,
    int limite = 50,
  }) async {
    final rows = await _client.rpc(
      RpcsSupabase.obtenerProductosCercanos,
      params: {
        'p_latitud': latitud,
        'p_longitud': longitud,
        'p_radio_km': radioKm,
        'p_limite': limite,
      },
    );

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ProductoDto.desdeSupabase)
        .toList();
  }

  @override

  /// Obtiene un producto concreto para la pantalla de detalle.
  Future<ProductoModel?> obtenerProductoPorId(String productoId) async {
    final row = await _client
        .from(TablasSupabase.productos)
        .select(productoSelect)
        .eq('id', productoId)
        .maybeSingle();

    if (row == null) return null;
    return ProductoDto.desdeSupabase(row);
  }

  @override

  /// Lista los productos disponibles del propietario actual.
  Future<List<ProductoModel>> obtenerMisProductosDisponibles(
    String propietarioId,
  ) async {
    final rows = await _client
        .from(TablasSupabase.productos)
        .select(productoSelect)
        .eq('propietario_id', propietarioId)
        .eq('estado', EstadoProducto.disponible)
        .order('creado_en', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map(ProductoDto.desdeSupabase)
        .toList();
  }

  @override

  /// Inserta el producto y resuelve su versión final desde la base de datos.
  ///
  /// Cada imagen de [imagenes] se sube en orden a Storage y se registra en
  /// `imagenes_producto` con su [posicion] (0 = portada). Si la subida de
  /// alguna imagen falla, el producto queda creado pero con menos imagenes
  /// que las pedidas; la UI puede reintentar mediante una futura accion de
  /// edicion.
  @override
  Future<ProductoModel> crearProducto(
    ProductoModel producto, {
    required LatLng ubicacionExacta,
    List<ImagenSeleccionada> imagenes = const [],
  }) async {
    final inserted = await _client
        .from(TablasSupabase.productos)
        .insert(
            ProductoDto.aInsercion(producto, ubicacionExacta: ubicacionExacta))
        .select('id')
        .single();

    final productoId = inserted['id'] as String;

    for (var i = 0; i < imagenes.length; i++) {
      final img = imagenes[i];
      if (img.bytes.isEmpty) continue;
      await _subirImagenProducto(
        productoId: productoId,
        propietarioId: producto.propietario.id,
        bytes: img.bytes,
        extension: img.extension,
        posicion: i,
      );
    }

    final rows = await _client
        .from(TablasSupabase.productos)
        .select(productoSelect)
        .eq('id', productoId)
        .limit(1);

    return ProductoDto.desdeSupabase(rows.cast<Map<String, dynamic>>().first);
  }

  @override

  /// Llama a la RPC protegida que devuelve la ubicacion exacta del producto.
  ///
  /// Si el usuario no esta autorizado o el producto no existe, la RPC lanza
  /// una excepcion: este metodo deja que se propague para que la UI muestre el
  /// error con el patron habitual de `mostrarError`.
  Future<LatLng?> obtenerUbicacionExactaProducto(String productoId) async {
    final filas = await _client.rpc(
      RpcsSupabase.obtenerUbicacionExactaProducto,
      params: {'p_producto_id': productoId},
    );

    final lista = (filas as List<dynamic>?)?.cast<Map<String, dynamic>>();
    if (lista == null || lista.isEmpty) return null;

    final fila = lista.first;
    final lat = _toDoubleOrNull(fila['latitud_exacta']);
    final lng = _toDoubleOrNull(fila['longitud_exacta']);
    if (lat == null || lng == null) return null;

    return LatLng(
      lat,
      lng,
    );
  }

  /// Normaliza coordenadas que pueden llegar como `numeric` o como `String`.
  double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Sube la imagen al bucket de productos y registra su metadata relacional.
  Future<void> _subirImagenProducto({
    required String productoId,
    required String propietarioId,
    required Uint8List bytes,
    required String extension,
    required int posicion,
  }) async {
    final extensionNormalizada = extension.replaceAll('.', '').toLowerCase();
    final tipoContenido =
        extensionNormalizada == 'png' ? 'image/png' : 'image/jpeg';
    // El prefijo por propietario simplifica las políticas de escritura en
    // Storage. La marca temporal + posicion evita colisiones cuando se suben
    // varias imagenes del mismo producto en la misma operacion.
    final path =
        '$propietarioId/$productoId-${DateTime.now().millisecondsSinceEpoch}-$posicion.$extensionNormalizada';

    await _client.storage.from(BucketsSupabase.imagenesProductos).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: tipoContenido,
            upsert: false,
          ),
        );

    final urlPublica = _client.storage
        .from(BucketsSupabase.imagenesProductos)
        .getPublicUrl(path);

    await _client.from(TablasSupabase.imagenesProducto).insert({
      'producto_id': productoId,
      'ruta_storage': path,
      'url_publica': urlPublica,
      'posicion': posicion,
    });
  }
}
