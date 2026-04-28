import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers_refresher.dart';
import '../domain/entities/producto_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../solicitudes/providers/solicitud_oferta_repository_provider.dart';
import '../providers/producto_repository_provider.dart';

/// Gestiona el flujo de contacto y creación de solicitudes desde detalle.
final contactoProductoControllerProvider =
    NotifierProvider.autoDispose<ContactoProductoController, AsyncValue<void>>(
  ContactoProductoController.new,
);

/// Orquesta la preparación de intercambios y solicitudes de oferta.
class ContactoProductoController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<List<ProductoModel>> obtenerProductosIntercambioDisponibles(
    ProductoModel producto,
  ) async {
    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) {
      throw const AppException('Debes iniciar sesión');
    }

    final productos = await ref
        .read(productoRepositoryProvider)
        .obtenerMisProductosDisponibles(usuario.id);

    // Un trueque solo puede proponerse con productos propios, disponibles y
    // distintos al producto que se quiere solicitar.
    return productos
        .where(
          (candidate) =>
              candidate.id != producto.id &&
              candidate.tipo == TipoOferta.intercambio,
        )
        .toList();
  }

  Future<String> crearSolicitud({
    required ProductoModel producto,
    String? productoOfrecidoId,
  }) async {
    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) {
      throw const AppException('Debes iniciar sesión');
    }

    final tipoSolicitud = producto.tipo == TipoOferta.venta
        ? TipoOferta.venta
        : TipoOferta.intercambio;

    state = const AsyncValue.loading();
    try {
      final solicitud = await ref
          .read(solicitudOfertaRepositoryProvider)
          .crearSolicitudOferta(
            productoId: producto.id,
            tipoSolicitud: tipoSolicitud,
            productoOfrecidoId: productoOfrecidoId,
            mensaje: 'Hola, me interesa tu oferta.',
          );

      // La creación de una solicitud impacta al panel y a las conversaciones.
      ref.refrescarPedidos();
      ref.refrescarChats();
      state = const AsyncValue.data(null);
      return solicitud.conversacionId;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
