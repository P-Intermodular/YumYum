import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/providers_refresher.dart';
import '../providers/solicitud_oferta_repository_provider.dart';

/// Gestiona las decisiones del usuario sobre solicitudes recibidas.
final solicitudOfertaControllerProvider = StateNotifierProvider.autoDispose<
    SolicitudOfertaController, AsyncValue<void>>((ref) {
  return SolicitudOfertaController(ref);
});

/// Orquesta la aceptación y denegación de solicitudes desde pedidos.
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

  /// Deniega la solicitud indicada y refresca las vistas afectadas.
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

  /// Invalida las consultas que reflejan solicitudes, catálogo y conversaciones.
  void _refrescarDatos() {
    _ref.refrescarPedidos();
    _ref.refrescarCatalogo();
    _ref.refrescarChats();
  }
}
