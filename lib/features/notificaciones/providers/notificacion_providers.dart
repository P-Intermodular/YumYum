import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../data/repositories/supabase_notificacion_repository.dart';
import '../domain/entities/notificacion_model.dart';
import '../domain/repositories/notificacion_repository.dart';
import '../../auth/controllers/auth_controller.dart';

/// Inyecta la implementación de notificaciones respaldada por Supabase.
final notificacionRepositoryProvider = Provider<NotificacionRepository>((ref) {
  return SupabaseNotificacionRepository(ref.watch(supabaseClientProvider));
});

/// Stream en tiempo real de todas las notificaciones del usuario autenticado.
final notificacionesProvider =
    StreamProvider<List<NotificacionModel>>((ref) {
  final usuario = ref.watch(autenticacionProvider).value;
  if (usuario == null) return const Stream.empty();

  return ref.watch(notificacionRepositoryProvider).obtenerNotificaciones(
        usuario.id,
      );
});

/// Contador de notificaciones no leídas para el badge de la campana.
final contadorNotificacionesNoLeidasProvider = Provider<int>((ref) {
  final notificaciones = ref.watch(notificacionesProvider).value;
  if (notificaciones == null) return 0;
  return notificaciones.where((n) => n.noLeida).length;
});
