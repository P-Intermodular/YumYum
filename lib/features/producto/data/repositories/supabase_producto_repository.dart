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

  @override
  Future<List<ImagenSeleccionada>> obtenerImagenesProducto(
    String productoId,
  ) async {
    final rows = await _client
        .from(TablasSupabase.imagenesProducto)
        .select('id, ruta_storage, url_publica, posicion')
        .eq('producto_id', productoId)
        .order('posicion', ascending: true);

    return rows.cast<Map<String, dynamic>>().map((row) {
      return ImagenSeleccionada.existente(
        id: row['id'] as String,
        urlRemota: row['url_publica'] as String? ?? '',
        rutaStorage: row['ruta_storage'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<void> actualizarProducto({
    required String productoId,
    required ProductoModel producto,
    required List<ImagenSeleccionada> imagenesFinales,
    required List<String> idsImagenesAEliminar,
  }) async {
    // 1. Actualizar campos editables del producto. No tocamos propietario_id
    //    ni creado_en (inmutables) ni latitud/longitud_exacta (no editable
    //    desde aquí en esta versión).
    await _client.from(TablasSupabase.productos).update({
      'titulo': producto.titulo,
      'descripcion': producto.descripcion,
      'tipo_oferta': producto.tipo,
      'precio': producto.tipo == 'venta' ? producto.precio : null,
      'categoria': producto.categoria,
      'etiquetas': producto.etiquetas,
      'alergenos': producto.alergenos,
      'sin_alergenos_declarados': producto.sinAlergenosDeclarados,
      'raciones_totales': producto.racionesTotales,
      'raciones_disponibles': producto.racionesDisponibles,
      'latitud_publica': producto.ubicacionPublica.latitude,
      'longitud_publica': producto.ubicacionPublica.longitude,
    }).eq('id', productoId);

    // 2. Eliminar las filas marcadas (recuperando ruta_storage para borrar
    //    los blobs después). Hacemos antes el SELECT para no perder la ruta
    //    una vez borrada la fila.
    if (idsImagenesAEliminar.isNotEmpty) {
      final rutasABorrar = (await _client
              .from(TablasSupabase.imagenesProducto)
              .select('ruta_storage')
              .inFilter('id', idsImagenesAEliminar))
          .cast<Map<String, dynamic>>()
          .map((row) => row['ruta_storage'] as String?)
          .whereType<String>()
          .toList();

      await _client
          .from(TablasSupabase.imagenesProducto)
          .delete()
          .inFilter('id', idsImagenesAEliminar);

      if (rutasABorrar.isNotEmpty) {
        await _client.storage
            .from(BucketsSupabase.imagenesProductos)
            .remove(rutasABorrar);
      }
    }

    // 3. Subir las nuevas imágenes con posiciones que continúen tras las
    //    existentes que se mantienen. Mantener el orden del array UI no es
    //    estrictamente fiable porque no reordenamos las existentes — el
    //    cliente pinta por `posicion ASC` y la portada (min) sobrevive.
    final nuevas = imagenesFinales.where((img) => !img.esExistente).toList();
    if (nuevas.isNotEmpty) {
      final maxRow = await _client
          .from(TablasSupabase.imagenesProducto)
          .select('posicion')
          .eq('producto_id', productoId)
          .order('posicion', ascending: false)
          .limit(1)
          .maybeSingle();
      var siguiente = (maxRow?['posicion'] as int? ?? -1) + 1;

      for (final img in nuevas) {
        if (img.bytes.isEmpty) continue;
        await _subirImagenProducto(
          productoId: productoId,
          propietarioId: producto.propietario.id,
          bytes: img.bytes,
          extension: img.extension,
          posicion: siguiente,
        );
        siguiente++;
      }
    }
  }

  @override
  Future<bool> eliminarProducto(String productoId) async {
    // Recuperamos las rutas antes de la RPC: si se hace DELETE real, las
    // filas en imagenes_producto desaparecerán por CASCADE y perderíamos la
    // referencia a los blobs.
    final rutas = (await _client
            .from(TablasSupabase.imagenesProducto)
            .select('ruta_storage')
            .eq('producto_id', productoId))
        .cast<Map<String, dynamic>>()
        .map((row) => row['ruta_storage'] as String?)
        .whereType<String>()
        .toList();

    final fueDeleteReal = await _client.rpc(
      RpcsSupabase.eliminarProducto,
      params: {'p_producto_id': productoId},
    ) as bool;

    if (fueDeleteReal && rutas.isNotEmpty) {
      await _client.storage
          .from(BucketsSupabase.imagenesProductos)
          .remove(rutas);
    }

    return fueDeleteReal;
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
