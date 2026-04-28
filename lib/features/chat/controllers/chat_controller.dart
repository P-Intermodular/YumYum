import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/entities/conversacion_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/chat_repository_provider.dart';

/// Gestiona el envío de mensajes desde la pantalla de chat.
final chatControllerProvider =
    StateNotifierProvider.autoDispose<ChatController, AsyncValue<void>>((ref) {
  return ChatController(ref);
});

/// Construye mensajes válidos y delega la persistencia en el repositorio.
class ChatController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ChatController(this._ref) : super(const AsyncValue.data(null));

  Future<void> enviarMensaje(String chatId, String texto) async {
    final contenido = texto.trim();
    if (contenido.isEmpty) return;

    final usuario = _ref.read(autenticacionProvider).value;
    if (usuario == null) {
      throw const AppException('Debes iniciar sesión');
    }

    state = const AsyncValue.loading();
    try {
      // Se genera un identificador cliente para mantener el modelo completo,
      // aunque la base de datos sea quien decide el identificador persistido.
      final mensaje = MensajeModel(
        id: const Uuid().v4(),
        texto: contenido,
        remitenteId: usuario.id,
        creadoEn: DateTime.now(),
      );

      await _ref.read(chatRepositoryProvider).enviarMensaje(chatId, mensaje);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
