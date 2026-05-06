import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/ui/yum_app_bar.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_card.dart';
import '../providers/chat_providers.dart';

/// Pantalla que muestra la bandeja de conversaciones del usuario.
class ListaChatsScreen extends ConsumerWidget {
  const ListaChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(listaChatsProvider);
    final colors = context.yumColors;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const YumAppBar(title: 'Mensajes', showBack: false),
      body: YumBackground(
        child: chatsAsync.when(
          data: (chats) {
            if (chats.isEmpty) {
              return Center(
                child: Text(
                  'No tienes mensajes todavía.',
                  style: TextStyle(color: colors.inkSoft, fontSize: 16),
                ),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                bottom: 120, // espacio para el nav
                left: 16,
                right: 16,
              ),
              itemCount: chats.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final chat = chats[index];
                final hasUnread = chat.mensajesNoLeidos > 0;
                
                return YumCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => context.push(RutasApp.chat(chat.id)),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: hasUnread ? colors.terracotta : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: AvatarUsuario(
                              nombre: chat.participante.nombre,
                              identificadorColor: chat.participante.id,
                              urlImagen: chat.participante.urlImagenPerfil,
                              radius: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chat.participante.nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: colors.ink,
                                  ),
                                ),
                                if (chat.producto != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.restaurant_outlined,
                                        size: 13,
                                        color: colors.inkSoft,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          chat.producto!.titulo,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.inkSoft,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  chat.ultimoMensaje?.texto ?? 'Chat iniciado',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: hasUnread ? colors.ink : colors.inkSoft,
                                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (chat.ultimoMensaje != null)
                                Text(
                                  DateFormat('HH:mm').format(chat.ultimoMensaje!.creadoEn),
                                  style: TextStyle(
                                    color: hasUnread ? colors.terracotta : colors.inkSoft,
                                    fontSize: 12,
                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              if (hasUnread)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.terracotta,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    chat.mensajesNoLeidos.toString(),
                                    style: TextStyle(
                                      color: colors.paper,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text(mensajeError(e))),
        ),
      ),
    );
  }
}
