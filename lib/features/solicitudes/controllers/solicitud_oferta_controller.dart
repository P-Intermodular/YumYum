import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers_refresher.dart';
import '../providers/solicitud_oferta_repository_provider.dart';

/// Gestiona las decisiones del usuario sobre solicitudes recibidas.
final solicitudOfertaControllerProvider =
    NotifierProvider.autoDispose<SolicitudOfertaController, AsyncValue<void>>(
  SolicitudOfertaController.new,
);

/// Orquesta la aceptación y denegación de solicitudes desde pedidos.
class SolicitudOfertaController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> aceptar(String solicitudId) async {
    final keepAlive = ref.keepAlive();
    state = const AsyncValue.loading();
    try {
      await ref
          .read(solicitudOfertaRepositoryProvider)
          .aceptarSolicitudOferta(solicitudId);
      _refrescarDatos();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      keepAlive.close();
    }
  }

  /// Deniega la solicitud indicada y refresca las vistas afectadas.
  Future<void> denegar(String solicitudId) async {
    final keepAlive = ref.keepAlive();
    state = const AsyncValue.loading();
    try {
      await ref
          .read(solicitudOfertaRepositoryProvider)
          .denegarSolicitudOferta(solicitudId);
      _refrescarDatos();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      keepAlive.close();
    }
  }

  /// Cancela una solicitud pendiente enviada por el usuario y refresca.
  Future<void> cancelar(String solicitudId) async {
    final keepAlive = ref.keepAlive();
    state = const AsyncValue.loading();
    try {
      await ref
          .read(solicitudOfertaRepositoryProvider)
          .cancelarSolicitudOferta(solicitudId);
      _refrescarDatos();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      keepAlive.close();
    }
  }

  /// Invalida las consultas que reflejan solicitudes, catálogo y conversaciones.
  void _refrescarDatos() {
    ref.refrescarPedidos();
    ref.refrescarCatalogo();
    ref.refrescarChats();
  }
}

