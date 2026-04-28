import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumyum/core/errors/app_exception.dart';
import 'package:yumyum/features/auth/controllers/auth_controller.dart';
import 'package:yumyum/features/auth/domain/entities/usuario_model.dart';
import 'package:yumyum/features/auth/domain/repositories/auth_repository.dart';
import 'package:yumyum/features/chat/controllers/chat_controller.dart';
import 'package:yumyum/features/chat/domain/entities/conversacion_model.dart';
import 'package:yumyum/features/chat/domain/repositories/chat_repository.dart';
import 'package:yumyum/features/chat/providers/chat_repository_provider.dart';

void main() {
  group('ChatController', () {
    test('ignora mensajes vacios', () async {
      final chatRepository = _ChatRepositoryFake();
      final container = _crearContainer(
        usuario: _usuario(),
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
        usuario: _usuario(),
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
      autenticacionProvider.overrideWith(
        (ref) => AutenticacionNotifier(
          _AuthRepositoryFake(usuarioActual: usuario),
          SupabaseClient('https://example.supabase.co', 'anon-key'),
        ),
      ),
      chatRepositoryProvider.overrideWithValue(chatRepository),
    ],
  );
}

UsuarioModel _usuario() {
  return const UsuarioModel(
    id: 'usuario-1',
    nombre: 'Ana',
    correo: 'ana@example.com',
    urlImagenPerfil: '',
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
  Stream<List<MensajeModel>> obtenerMensajes(String conversacionId) {
    return const Stream.empty();
  }

  @override
  Future<void> enviarMensaje(
      String conversacionId, MensajeModel mensaje) async {
    mensajesEnviados.add(_MensajeEnviado(conversacionId, mensaje));
  }
}

class _AuthRepositoryFake implements AuthRepository {
  final UsuarioModel? usuarioActual;

  const _AuthRepositoryFake({required this.usuarioActual});

  @override
  Future<UsuarioModel> iniciarSesion(String correo, String password) {
    throw UnimplementedError();
  }

  @override
  Future<UsuarioModel> registrarUsuario(
    String nombre,
    String correo,
    String password,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> cerrarSesion() async {}

  @override
  Future<UsuarioModel?> obtenerUsuarioActual() async => usuarioActual;

  @override
  Future<UsuarioModel> actualizarPerfil(UsuarioModel usuario) {
    throw UnimplementedError();
  }

  @override
  Future<UsuarioModel> actualizarUbicacionPredeterminada(UsuarioModel usuario) {
    throw UnimplementedError();
  }

  @override
  Future<void> enviarEmailRecuperacion(String correo) {
    throw UnimplementedError();
  }

  @override
  Future<void> verificarRecuperacionPassword(String tokenHash) {
    throw UnimplementedError();
  }

  @override
  Future<void> verificarCodigoRecuperacionPassword(String codigo) {
    throw UnimplementedError();
  }

  @override
  Future<void> restablecerPassword(String nuevaPassword) {
    throw UnimplementedError();
  }
}
