import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/constants/ubicaciones_app.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/entities/producto_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/producto_providers.dart';
import '../providers/producto_repository_provider.dart';
import 'datos_publicacion_producto.dart';

final publicarProductoControllerProvider = StateNotifierProvider.autoDispose<
    PublicarProductoController, AsyncValue<void>>((ref) {
  return PublicarProductoController(ref);
});

class PublicarProductoController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  PublicarProductoController(this._ref) : super(const AsyncValue.data(null));

  Future<void> publicar(DatosPublicacionProducto datos) async {
    final usuario = _ref.read(autenticacionProvider).value;
    if (usuario == null) {
      throw const AppException('Debes iniciar sesion');
    }

    state = const AsyncValue.loading();
    try {
      final nuevoProducto = ProductoModel(
        id: '',
        titulo: datos.titulo,
        descripcion: datos.descripcion,
        urlImagen: '',
        propietario: usuario,
        creadoEn: DateTime.now(),
        tipo: datos.tipo,
        estado: EstadoProducto.disponible,
        precio: datos.tipo == TipoOferta.venta ? datos.precio : null,
        ubicacion: UbicacionesApp.madridCentro,
      );

      await _ref.read(productoRepositoryProvider).crearProducto(
            nuevoProducto,
            bytesImagen: datos.bytesImagen,
            extensionImagen: datos.extensionImagen,
          );

      _ref.invalidate(productosProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
