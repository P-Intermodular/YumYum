import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/conversacion_model.dart';
import '../../auth/controllers/auth_controller.dart';
import 'chat_repository_provider.dart';

/// Bandeja de chats del usuario autenticado (en tiempo real).
final listaChatsProvider = StreamProvider.autoDispose<List<ConversacionModel>>((ref) {
  final usuario = ref.watch(autenticacionProvider).value;
  if (usuario == null) return const Stream.empty();

  return ref.watch(chatRepositoryProvider).escucharChats(usuario.id);
});

/// Stream de mensajes para una conversación concreta.
final mensajesProvider = StreamProvider.autoDispose
    .family<List<MensajeModel>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).obtenerMensajes(chatId);
});
