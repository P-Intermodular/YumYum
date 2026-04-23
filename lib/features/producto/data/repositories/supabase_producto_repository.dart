import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/estados_app.dart';
import '../../../../core/constants/supabase_names.dart';
import '../../domain/repositories/producto_repository.dart';
import '../../domain/entities/producto_model.dart';
import '../dtos/producto_dto.dart';

class SupabaseProductoRepository implements ProductoRepository {
  static const productoSelect = '''
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
  Future<ProductoModel> crearProducto(
    ProductoModel producto, {
    Uint8List? bytesImagen,
    String extensionImagen = 'jpg',
  }) async {
    final inserted = await _client
        .from(TablasSupabase.productos)
        .insert(ProductoDto.aInsercion(producto))
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
        .from(TablasSupabase.productos)
        .select(productoSelect)
        .eq('id', productoId)
        .limit(1);

    return ProductoDto.desdeSupabase(rows.cast<Map<String, dynamic>>().first);
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
      'posicion': 0,
    });
  }
}
