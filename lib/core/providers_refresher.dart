import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chat/providers/chat_providers.dart';
import '../features/mapa/providers/mapa_providers.dart';
import '../features/pedidos/providers/transaccion_providers.dart';
import '../features/perfil/providers/perfil_providers.dart';
import '../features/solicitudes/providers/solicitud_oferta_providers.dart';
import '../features/producto/providers/producto_providers.dart';
import '../features/valoraciones/providers/valoracion_providers.dart';
import 'location/ubicacion_actual_provider.dart';

/// Invalidaciones agrupadas por intención de negocio.
extension RefrescarProviders on Ref {
  void refrescarCatalogo() {
    invalidate(productosProvider);
    invalidate(productosCercanosProvider);
    invalidate(productosMapaProvider);
    invalidate(misProductosProvider);
  }

  void refrescarPedidos() {
    invalidate(solicitudesRecibidasProvider);
    invalidate(solicitudesEnviadasProvider);
    invalidate(transaccionesListProvider);
  }

  void refrescarChats() {
    invalidate(listaChatsProvider);
  }

  void refrescarUbicacionActual() {
    invalidate(ubicacionActualProvider);
  }

  void refrescarUbicacionYProductosCercanos() {
    invalidate(ubicacionActualProvider);
    invalidate(productosCercanosProvider);
    invalidate(productosMapaProvider);
  }

  void refrescarProductoDetalle(String productoId) {
    invalidate(productoDetalleProvider(productoId));
  }

  void refrescarTransaccionDetalle(String transaccionId) {
    invalidate(transaccionDetalleProvider(transaccionId));
  }

  void refrescarValoracionUsuario({
    required String transaccionId,
    required String usuarioId,
  }) {
    invalidate(valoracionUsuarioProvider((transaccionId, usuarioId)));
  }

  void refrescarValoracionesRecibidas(String usuarioId) {
    invalidate(valoracionesRecibidasProvider(usuarioId));
  }
}

/// Variante para widgets, donde Riverpod expone [WidgetRef].
extension RefrescarProvidersWidget on WidgetRef {
  void refrescarUbicacionActual() {
    invalidate(ubicacionActualProvider);
  }

  void refrescarUbicacionYProductosCercanos() {
    invalidate(ubicacionActualProvider);
    invalidate(productosCercanosProvider);
    invalidate(productosMapaProvider);
  }
}
