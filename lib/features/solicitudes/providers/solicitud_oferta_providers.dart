import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../domain/entities/solicitud_oferta_model.dart';
import 'solicitud_oferta_repository_provider.dart';

/// Escucha en tiempo real las solicitudes que el usuario debe revisar como propietario.
final solicitudesRecibidasProvider =
    StreamProvider.autoDispose<List<SolicitudOfertaModel>>((ref) {
  final usuario = ref.watch(autenticacionProvider).value;
  if (usuario == null) return const Stream.empty();

  return ref
      .watch(solicitudOfertaRepositoryProvider)
      .escucharSolicitudesRecibidas(usuario.id);
});

/// Escucha en tiempo real las solicitudes creadas por el usuario autenticado.
final solicitudesEnviadasProvider =
    StreamProvider.autoDispose<List<SolicitudOfertaModel>>((ref) {
  final usuario = ref.watch(autenticacionProvider).value;
  if (usuario == null) return const Stream.empty();

  return ref
      .watch(solicitudOfertaRepositoryProvider)
      .escucharSolicitudesEnviadas(usuario.id);
});
