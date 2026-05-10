import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/domain/entities/usuario_model.dart';
import '../data/repositories/supabase_notificacion_repository.dart';
import '../domain/entities/notificacion_model.dart';
import '../domain/repositories/notificacion_repository.dart';

/// Inyecta la implementación de notificaciones respaldada por Supabase.
final notificacionRepositoryProvider = Provider<NotificacionRepository>((ref) {
  return SupabaseNotificacionRepository(ref.watch(supabaseClientProvider));
});

/// Stream en tiempo real de notificaciones del usuario autenticado,
/// **filtradas** según `preferencias_notificaciones` del perfil. Las de
/// categorías desactivadas no llegan a la UI ni cuentan para el badge —
/// siguen llegando al backend, simplemente no se muestran.
final notificacionesProvider =
    StreamProvider<List<NotificacionModel>>((ref) {
  final usuario = ref.watch(autenticacionProvider).value;
  if (usuario == null) return const Stream.empty();

  return ref
      .watch(notificacionRepositoryProvider)
      .obtenerNotificaciones(usuario.id)
      .map(
        (lista) => lista.where((n) => _aceptada(n.tipo, usuario)).toList(),
      );
});

/// Contador de notificaciones no leídas para el badge de la campana.
/// Hereda automáticamente el filtrado de [notificacionesProvider].
final contadorNotificacionesNoLeidasProvider = Provider<int>((ref) {
  final notificaciones = ref.watch(notificacionesProvider).value;
  if (notificaciones == null) return 0;
  return notificaciones.where((n) => n.noLeida).length;
});

/// Decide si la notificación debe mostrarse según las preferencias del
/// usuario. Si el tipo no está clasificado (categoría null), pasa siempre
/// — así nuevos tipos futuros no quedan silenciados por accidente hasta
/// que se mapeen.
bool _aceptada(String tipo, UsuarioModel usuario) {
  final categoria = _categoriaDeTipo(tipo);
  if (categoria == null) return true;
  return usuario.puedeRecibir(categoria);
}

/// Mapea cada `tipo` de la tabla `notificaciones` (escrito por las RPCs
/// del backend) a una de las tres categorías de preferencia.
String? _categoriaDeTipo(String tipo) {
  if (tipo.startsWith('solicitud_oferta') ||
      tipo.startsWith('transaccion')) {
    return 'pedidos';
  }
  if (tipo.startsWith('mensaje')) return 'mensajes';
  if (tipo.startsWith('valoracion')) return 'valoraciones';
  return null;
}
