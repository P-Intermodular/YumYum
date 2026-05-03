import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../providers/chat_providers.dart';
import '../providers/chat_repository_provider.dart';

/// Pantalla de conversación en tiempo real entre dos usuarios.
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _mensajeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _marcarMensajesComoLeidos();
  }

  /// Marca los mensajes ajenos de esta conversación como leídos.
  Future<void> _marcarMensajesComoLeidos() async {
    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) return;
    try {
      await ref
          .read(chatRepositoryProvider)
          .marcarMensajesLeidos(widget.chatId, usuario.id);
    } catch (e) {
      // Fallo silencioso en la UI, pero lo logueamos en consola para debug.
      debugPrint('Error al marcar mensajes como leídos: $e');
    }
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    super.dispose();
  }

  /// Envía el contenido actual del campo de texto y limpia la caja al terminar.
  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    try {
      await ref
          .read(chatControllerProvider.notifier)
          .enviarMensaje(widget.chatId, texto);
      _mensajeController.clear();
    } catch (error) {
      if (mounted) {
        mostrarError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mensajesAsync = ref.watch(mensajesProvider(widget.chatId));
    final usuarioActual = ref.watch(autenticacionProvider).value;

    return Scaffold(
      appBar: const YumYumAppBar(
          titulo: 'Chat', mostrarBotonVolver: true, mostrarBotonPerfil: false),
      body: Column(
        children: [
          Expanded(
            child: mensajesAsync.when(
              data: (mensajes) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: false,
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    final mensaje = mensajes[index];
                    // La alineación diferencia visualmente mensajes propios y ajenos.
                    final esMio = mensaje.remitenteId == usuarioActual?.id;

                    return Align(
                      alignment:
                          esMio ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: esMio
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight:
                                esMio ? const Radius.circular(0) : null,
                            bottomLeft:
                                !esMio ? const Radius.circular(0) : null,
                          ),
                        ),
                        child: Text(
                          mensaje.texto,
                          style: TextStyle(
                              color: esMio
                                  ? Colors.green.shade900
                                  : Colors.black87),
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensajeController,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _enviarMensaje(),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
