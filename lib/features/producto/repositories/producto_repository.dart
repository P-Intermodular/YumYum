import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../../models/producto_model.dart';

abstract class ProductoRepository {
  Future<List<ProductoModel>> obtenerProductos();
  Future<ProductoModel?> obtenerProductoPorId(String productoId);
  Future<List<ProductoModel>> obtenerMisProductosDisponibles(
      String propietarioId);
  Future<ProductoModel> crearProducto(
    ProductoModel producto, {
    Uint8List? bytesImagen,
    String extensionImagen,
  });
}

final productoRepositoryProvider = Provider<ProductoRepository>((ref) {
  return SupabaseProductoRepository(ref.watch(supabaseClientProvider));
});

class SupabaseProductoRepository implements ProductoRepository {
  static const _productoSelect = '''
    id,
    propietario_id,
    titulo,
    descripcion,
    tipo_oferta,
    precio,
    estado,
    latitud_publica,
    longitud_publica,
    creado_en,
    perfiles:propietario_id(
      id,
      nombre,
      email,
      url_avatar,
      ciudad,
      preferencias,
      certificacion_sanitaria,
      es_moderador,
      valoracion_media,
      numero_valoraciones
    ),
    imagenes_producto(
      url_publica,
      ruta_storage,
      posicion
    )
  ''';

  final SupabaseClient _client;

  SupabaseProductoRepository(this._client);

  @override
  Future<List<ProductoModel>> obtenerProductos() async {
    final rows = await _client
        .from('productos')
        .select(_productoSelect)
        .eq('estado', 'disponible')
        .order('creado_en', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map(ProductoModel.desdeSupabase)
        .toList();
  }

  @override
  Future<ProductoModel?> obtenerProductoPorId(String productoId) async {
    final row = await _client
        .from('productos')
        .select(_productoSelect)
        .eq('id', productoId)
        .maybeSingle();

    if (row == null) return null;
    return ProductoModel.desdeSupabase(row);
  }

  @override
  Future<List<ProductoModel>> obtenerMisProductosDisponibles(
      String propietarioId) async {
    final rows = await _client
        .from('productos')
        .select(_productoSelect)
        .eq('propietario_id', propietarioId)
        .eq('estado', 'disponible')
        .order('creado_en', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map(ProductoModel.desdeSupabase)
        .toList();
  }

  @override
  Future<ProductoModel> crearProducto(
    ProductoModel producto, {
    Uint8List? bytesImagen,
    String extensionImagen = 'jpg',
  }) async {
    final inserted = await _client
        .from('productos')
        .insert(producto.aInsercionProducto())
        .select('id')
        .single();

    final productoId = inserted['id'] as String;

    if (bytesImagen != null && bytesImagen.isNotEmpty) {
      await _subirImagenProducto(
        productoId: productoId,
        propietarioId: producto.propietario.id,
        bytes: bytesImagen,
        extension: extensionImagen,
      );
    }

    final rows = await _client
        .from('productos')
        .select(_productoSelect)
        .eq('id', productoId)
        .limit(1);

    return ProductoModel.desdeSupabase(rows.cast<Map<String, dynamic>>().first);
  }

  Future<void> _subirImagenProducto({
    required String productoId,
    required String propietarioId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final extensionNormalizada = extension.replaceAll('.', '').toLowerCase();
    final tipoContenido =
        extensionNormalizada == 'png' ? 'image/png' : 'image/jpeg';
    final path =
        '$propietarioId/$productoId-${DateTime.now().millisecondsSinceEpoch}.$extensionNormalizada';

    await _client.storage.from('imagenes-productos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: tipoContenido,
            upsert: false,
          ),
        );

    final urlPublica =
        _client.storage.from('imagenes-productos').getPublicUrl(path);

    await _client.from('imagenes_producto').insert({
      'producto_id': productoId,
      'ruta_storage': path,
      'url_publica': urlPublica,
      'posicion': 0,
    });
  }
}
