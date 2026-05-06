import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers_refresher.dart';
import '../domain/entities/producto_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/producto_repository_provider.dart';
import 'datos_publicacion_producto.dart';

/// Gestiona la publicación de productos desde la UI.
final publicarProductoControllerProvider =
    NotifierProvider.autoDispose<PublicarProductoController, AsyncValue<void>>(
  PublicarProductoController.new,
);

/// Construye el producto de dominio y delega su persistencia en el repositorio.
class PublicarProductoController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> publicar(DatosPublicacionProducto datos) async {
    final keepAlive = ref.keepAlive();
    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) {
      keepAlive.close();
      throw const AppException('Debes iniciar sesión');
    }

    state = const AsyncValue.loading();
    try {
      final ubicacionPublica = _calcularUbicacionPublica(datos.ubicacionExacta);

      final nuevoProducto = ProductoModel(
        id: '',
        titulo: datos.titulo,
        descripcion: datos.descripcion,
        urlsImagenes: const [],
        propietario: usuario,
        creadoEn: DateTime.now(),
        tipo: datos.tipo,
        estado: EstadoProducto.disponible,
        precio: datos.tipo == TipoOferta.venta ? datos.precio : null,
        categoria: datos.categoria,
        etiquetas: datos.etiquetas,
        alergenos: datos.alergenos,
        sinAlergenosDeclarados: datos.sinAlergenosDeclarados,
        racionesTotales: datos.raciones,
        racionesDisponibles: datos.raciones,
        ubicacionPublica: ubicacionPublica,
      );

      await ref.read(productoRepositoryProvider).crearProducto(
            nuevoProducto,
            ubicacionExacta: datos.ubicacionExacta,
            imagenes: datos.imagenes,
          );

      // Tras publicar, el inicio, mapa y perfil deben resolver de nuevo datos.
      ref.refrescarCatalogo();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      keepAlive.close();
    }
  }

  /// Aplica una edición sobre un producto ya publicado y refresca el catálogo.
  ///
  /// La pantalla pasa la lista completa de imágenes que deben quedar tras la
  /// edición (mezcla de existentes que se conservan + nuevas para subir) y la
  /// lista de ids de imágenes existentes que el usuario marcó para borrar.
  /// El repositorio se encarga de mover Storage y `imagenes_producto`
  /// coherentemente.
  Future<void> actualizar({
    required String productoId,
    required ProductoModel producto,
    required List<ImagenSeleccionada> imagenesFinales,
    required List<String> idsImagenesAEliminar,
  }) async {
    final keepAlive = ref.keepAlive();
    state = const AsyncValue.loading();
    try {
      await ref.read(productoRepositoryProvider).actualizarProducto(
            productoId: productoId,
            producto: producto,
            imagenesFinales: imagenesFinales,
            idsImagenesAEliminar: idsImagenesAEliminar,
          );

      ref.refrescarCatalogo();
      ref.refrescarProductoDetalle(productoId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      keepAlive.close();
    }
  }

  /// Elimina el plato. La RPC decide internamente si es DELETE real (limpia
  /// Storage cliente-side) o soft delete por tener historial; el resultado
  /// se devuelve para informar al usuario si quiere mostrar copia distinta.
  Future<bool> eliminar(String productoId) async {
    final keepAlive = ref.keepAlive();
    state = const AsyncValue.loading();
    try {
      final fueDeleteReal =
          await ref.read(productoRepositoryProvider).eliminarProducto(productoId);

      ref.refrescarCatalogo();
      ref.refrescarProductoDetalle(productoId);
      state = const AsyncValue.data(null);
      return fueDeleteReal;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      keepAlive.close();
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
