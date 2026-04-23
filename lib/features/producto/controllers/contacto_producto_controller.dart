import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/entities/producto_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/providers/chat_providers.dart';
import '../../pedidos/providers/panel_pedidos_provider.dart';
import '../../solicitudes/providers/solicitud_oferta_repository_provider.dart';
import '../providers/producto_repository_provider.dart';

/// Gestiona el flujo de contacto y creación de solicitudes desde detalle.
final contactoProductoControllerProvider = StateNotifierProvider.autoDispose<
    ContactoProductoController, AsyncValue<void>>((ref) {
  return ContactoProductoController(ref);
});

/// Orquesta la preparación de intercambios y solicitudes de oferta.
class ContactoProductoController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ContactoProductoController(this._ref) : super(const AsyncValue.data(null));

  Future<List<ProductoModel>> obtenerProductosIntercambioDisponibles(
    ProductoModel producto,
  ) async {
    final usuario = _ref.read(autenticacionProvider).value;
    if (usuario == null) {
      throw const AppException('Debes iniciar sesion');
    }

    final productos = await _ref
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
    final usuario = _ref.read(autenticacionProvider).value;
    if (usuario == null) {
      throw const AppException('Debes iniciar sesion');
    }

    final tipoSolicitud = producto.tipo == TipoOferta.venta
        ? TipoOferta.venta
        : TipoOferta.intercambio;

    state = const AsyncValue.loading();
    try {
      final solicitud = await _ref
          .read(solicitudOfertaRepositoryProvider)
          .crearSolicitudOferta(
            productoId: producto.id,
            tipoSolicitud: tipoSolicitud,
            productoOfrecidoId: productoOfrecidoId,
            mensaje: 'Hola, me interesa tu oferta.',
          );

      // La creación de una solicitud impacta al panel de pedidos y a la lista
      // de chats porque el backend abre o reutiliza una conversación.
      _ref.invalidate(panelPedidosProvider);
      _ref.invalidate(listaChatsProvider);
      state = const AsyncValue.data(null);
      return solicitud.conversacionId;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
