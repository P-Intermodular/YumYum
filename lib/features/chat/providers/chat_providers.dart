import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/conversacion_model.dart';
import '../../auth/controllers/auth_controller.dart';
import 'chat_repository_provider.dart';

final listaChatsProvider = FutureProvider<List<ConversacionModel>>((ref) async {
  final usuario = ref.watch(autenticacionProvider).value;
  if (usuario == null) return [];

  return ref.watch(chatRepositoryProvider).obtenerChats(usuario.id);
});

final mensajesProvider =
    StreamProvider.family<List<MensajeModel>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).obtenerMensajes(chatId);
});
