import '../../../models/chat_model.dart';
import '../../../models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

abstract class ChatRepository {
  Future<List<ChatModel>> getChats(String userId);
  Stream<List<MessageModel>> getMessages(String chatId);
  Future<void> sendMessage(String chatId, MessageModel message);
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return MockChatRepository();
});

class MockChatRepository implements ChatRepository {
  final Map<String, List<MessageModel>> _messages = {
    'chat1': [
      MessageModel(
        id: 'm1',
        text: '¡Hola! ¿Aún tienes la tarta de manzana?',
        senderId: '1',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      MessageModel(
        id: 'm2',
        text: 'Sí, claro. ¿Por qué te gustaría intercambiarla?',
        senderId: '2',
        timestamp: DateTime.now().subtract(const Duration(minutes: 50)),
      ),
    ]
  };

  final List<ChatModel> _chats = [
    ChatModel(
      id: 'chat1',
      participant: UserModel(id: '2', name: 'Ana', email: 'ana@ejemplo.com', profileImageUrl: 'https://i.pravatar.cc/150?img=5'),
      lastMessage: MessageModel(
        id: 'm2',
        text: 'Sí, claro. ¿Por qué te gustaría intercambiarla?',
        senderId: '2',
        timestamp: DateTime.now().subtract(const Duration(minutes: 50)),
      ),
      unreadCount: 1,
    )
  ];

  final Map<String, StreamController<List<MessageModel>>> _controllers = {};

  @override
  Future<List<ChatModel>> getChats(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _chats;
  }

  @override
  Stream<List<MessageModel>> getMessages(String chatId) {
    if (!_controllers.containsKey(chatId)) {
      _controllers[chatId] = StreamController<List<MessageModel>>.broadcast();
      _messages[chatId] ??= [];
    }
    
    // Simulate initial delay then emit
    Future.delayed(const Duration(milliseconds: 400), () {
      _controllers[chatId]!.add(_messages[chatId]!.toList());
    });

    return _controllers[chatId]!.stream;
  }

  @override
  Future<void> sendMessage(String chatId, MessageModel message) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _messages[chatId] ??= [];
    _messages[chatId]!.add(message);
    
    _controllers[chatId]?.add(_messages[chatId]!.toList());

    // Auto-reply
    if (message.senderId == '1') {
      Future.delayed(const Duration(seconds: 2), () {
        final reply = MessageModel(
          id: const Uuid().v4(),
          text: 'Esta es una respuesta automática de prueba.',
          senderId: '2', // Other person
          timestamp: DateTime.now(),
        );
        _messages[chatId]!.add(reply);
        _controllers[chatId]?.add(_messages[chatId]!.toList());
      });
    }
  }
}
