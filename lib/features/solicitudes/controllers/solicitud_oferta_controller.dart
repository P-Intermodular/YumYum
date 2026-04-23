import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/providers/chat_providers.dart';
import '../../pedidos/providers/panel_pedidos_provider.dart';
import '../../producto/providers/producto_providers.dart';
import '../providers/solicitud_oferta_repository_provider.dart';

final solicitudOfertaControllerProvider = StateNotifierProvider.autoDispose<
    SolicitudOfertaController, AsyncValue<void>>((ref) {
  return SolicitudOfertaController(ref);
});

class SolicitudOfertaController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SolicitudOfertaController(this._ref) : super(const AsyncValue.data(null));

  Future<void> aceptar(String solicitudId) async {
    state = const AsyncValue.loading();
    try {
      await _ref
          .read(solicitudOfertaRepositoryProvider)
          .aceptarSolicitudOferta(solicitudId);
      _refrescarDatos();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> denegar(String solicitudId) async {
    state = const AsyncValue.loading();
    try {
      await _ref
          .read(solicitudOfertaRepositoryProvider)
          .denegarSolicitudOferta(solicitudId);
      _refrescarDatos();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void _refrescarDatos() {
    _ref.invalidate(panelPedidosProvider);
    _ref.invalidate(productosProvider);
    _ref.invalidate(listaChatsProvider);
  }
}
