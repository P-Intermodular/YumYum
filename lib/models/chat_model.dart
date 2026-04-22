import 'user_model.dart';

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
  });
}

class ChatModel {
  final String id;
  final UserModel participant; // The other user in the chat
  final MessageModel? lastMessage;
  final int unreadCount;

  ChatModel({
    required this.id,
    required this.participant,
    this.lastMessage,
    this.unreadCount = 0,
  });
}
