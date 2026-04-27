import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../perfil/providers/perfil_providers.dart';
import '../domain/entities/producto_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/producto_providers.dart';
import '../providers/producto_repository_provider.dart';
import 'datos_publicacion_producto.dart';

/// Gestiona la publicación de productos desde la UI.
final publicarProductoControllerProvider = StateNotifierProvider.autoDispose<
    PublicarProductoController, AsyncValue<void>>((ref) {
  return PublicarProductoController(ref);
});

/// Construye el producto de dominio y delega su persistencia en el repositorio.
class PublicarProductoController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  PublicarProductoController(this._ref) : super(const AsyncValue.data(null));

  Future<void> publicar(DatosPublicacionProducto datos) async {
    final usuario = _ref.read(autenticacionProvider).value;
    if (usuario == null) {
      throw const AppException('Debes iniciar sesión');
    }

    state = const AsyncValue.loading();
    try {
      final ubicacionPublica = _calcularUbicacionPublica(datos.ubicacionExacta);

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
        ubicacionPublica: ubicacionPublica,
      );

      await _ref.read(productoRepositoryProvider).crearProducto(
            nuevoProducto,
            ubicacionExacta: datos.ubicacionExacta,
            bytesImagen: datos.bytesImagen,
            extensionImagen: datos.extensionImagen,
          );

      // Tras publicar, el inicio y el mapa deben resolver de nuevo el catálogo.
      _ref.invalidate(productosProvider);
      _ref.invalidate(productosCercanosProvider);
      _ref.invalidate(misProductosProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Desplaza la ubicacion exacta entre 100 y 200 metros en una direccion
  /// aleatoria para que el feed muestre una posicion aproximada.
  LatLng _calcularUbicacionPublica(LatLng exacta) {
    final aleatorio = Random();
    final angulo = aleatorio.nextDouble() * 2 * pi;
    final distancia = 100 + aleatorio.nextDouble() * 100; // metros

    final dx = distancia * cos(angulo);
    final dy = distancia * sin(angulo);

    final deltaLat = dy / 111320.0;
    final deltaLng = dx / (111320.0 * cos(exacta.latitude * pi / 180));

    return LatLng(
      exacta.latitude + deltaLat,
      exacta.longitude + deltaLng,
    );
  }
}
