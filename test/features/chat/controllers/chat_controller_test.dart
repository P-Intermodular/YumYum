import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumyum/core/errors/app_exception.dart';
import 'package:yumyum/core/supabase/supabase_client_provider.dart';
import 'package:yumyum/features/auth/controllers/auth_controller.dart';
import 'package:yumyum/features/auth/domain/entities/usuario_model.dart';
import 'package:yumyum/features/auth/providers/auth_repository_provider.dart';
import 'package:yumyum/features/chat/controllers/chat_controller.dart';
import 'package:yumyum/features/chat/domain/entities/conversacion_model.dart';
import 'package:yumyum/features/chat/domain/repositories/chat_repository.dart';
import 'package:yumyum/features/chat/providers/chat_repository_provider.dart';

import '../../../helpers/auth_test_utils.dart';

void main() {
  group('ChatController', () {
    test('ignora mensajes vacios', () async {
      final chatRepository = _ChatRepositoryFake();
      final container = _crearContainer(
        usuario: usuarioTest(),
        chatRepository: chatRepository,
      );
      addTearDown(container.dispose);

      await container.read(chatControllerProvider.notifier).enviarMensaje(
            'chat-1',
            '   ',
          );

      expect(chatRepository.mensajesEnviados, isEmpty);
      expect(container.read(chatControllerProvider).isLoading, isFalse);
    });

    test('falla si no hay usuario autenticado', () async {
      final chatRepository = _ChatRepositoryFake();
      final container = _crearContainer(
        usuario: null,
        chatRepository: chatRepository,
      );
      addTearDown(container.dispose);

      container.read(autenticacionProvider);
      await container.pump();

      expect(
        () => container
            .read(chatControllerProvider.notifier)
            .enviarMensaje('chat-1', 'Hola'),
        throwsA(isA<AppException>()),
      );
      expect(chatRepository.mensajesEnviados, isEmpty);
    });

    test('envia mensaje con el usuario actual', () async {
      final chatRepository = _ChatRepositoryFake();
      final container = _crearContainer(
        usuario: usuarioTest(),
        chatRepository: chatRepository,
      );
      addTearDown(container.dispose);

      container.read(autenticacionProvider);
      await container.pump();

      await container
          .read(chatControllerProvider.notifier)
          .enviarMensaje('chat-1', '  Hola  ');

      expect(chatRepository.mensajesEnviados, hasLength(1));
      final enviado = chatRepository.mensajesEnviados.single;
      expect(enviado.chatId, 'chat-1');
      expect(enviado.mensaje.texto, 'Hola');
      expect(enviado.mensaje.remitenteId, 'usuario-1');
      expect(container.read(chatControllerProvider).hasError, isFalse);
      expect(container.read(chatControllerProvider).isLoading, isFalse);
    });
  });
}

ProviderContainer _crearContainer({
  required UsuarioModel? usuario,
  required _ChatRepositoryFake chatRepository,
}) {
  return ProviderContainer(
    overrides: [
      autenticacionRepositoryProvider.overrideWithValue(
        AuthRepositoryFake(usuarioActual: usuario),
      ),
      supabaseClientProvider.overrideWithValue(supabaseTestClient()),
      chatRepositoryProvider.overrideWithValue(chatRepository),
    ],
  );
}

class _MensajeEnviado {
  final String chatId;
  final MensajeModel mensaje;

  const _MensajeEnviado(this.chatId, this.mensaje);
}

class _ChatRepositoryFake implements ChatRepository {
  final mensajesEnviados = <_MensajeEnviado>[];

  @override
  Future<List<ConversacionModel>> obtenerChats(String usuarioId) async => [];

  @override
  Stream<List<ConversacionModel>> escucharChats(String usuarioId) {
    return Stream.value([]);
  }

  @override
  Stream<List<MensajeModel>> obtenerMensajes(String conversacionId) {
    return const Stream.empty();
  }

  @override
  Future<void> enviarMensaje(
      String conversacionId, MensajeModel mensaje) async {
    mensajesEnviados.add(_MensajeEnviado(conversacionId, mensaje));
  }

  @override
  Future<void> marcarMensajesLeidos(String conversacionId, String usuarioId) async {}
}
