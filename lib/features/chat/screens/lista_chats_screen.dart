import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../providers/chat_providers.dart';

/// Pantalla que muestra la bandeja de conversaciones del usuario.
class ListaChatsScreen extends ConsumerWidget {
  const ListaChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(listaChatsProvider);

    return Scaffold(
      appBar: const YumYumAppBar(titulo: 'Mensajes'),
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
                leading: AvatarUsuario(
                  nombre: chat.participante.nombre,
                  identificadorColor: chat.participante.id,
                  urlImagen: chat.participante.urlImagenPerfil,
                ),
                title: Text(chat.participante.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  chat.ultimoMensaje?.texto ?? 'Chat iniciado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (chat.ultimoMensaje != null)
                      Text(
                        DateFormat('HH:mm')
                            .format(chat.ultimoMensaje!.creadoEn),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    if (chat.mensajesNoLeidos > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          chat.mensajesNoLeidos.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      )
                  ],
                ),
                onTap: () => context.push(RutasApp.chat(chat.id)),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(mensajeError(e))),
      ),
    );
  }
}
