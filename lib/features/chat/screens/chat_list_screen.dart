import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/chat_model.dart';
import '../repositories/chat_repository.dart';
import '../../auth/providers/auth_provider.dart';

final chatsProvider = FutureProvider<List<ChatModel>>((ref) async {
  final user = ref.read(authProvider).value;
  if (user == null) return [];
  return ref.watch(chatRepositoryProvider).getChats(user.id);
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(child: Text('No tienes mensajes todavía.'));
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(chat.participant.profileImageUrl),
                ),
                title: Text(chat.participant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  chat.lastMessage?.text ?? 'Chat iniciado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (chat.lastMessage != null)
                      Text(
                        DateFormat('HH:mm').format(chat.lastMessage!.timestamp),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    if (chat.unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          chat.unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      )
                  ],
                ),
                onTap: () => context.push('/chat_room/${chat.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
