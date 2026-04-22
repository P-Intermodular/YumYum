import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../models/conversacion_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../providers/chat_providers.dart';
import '../repositories/chat_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _mensajeController = TextEditingController();

  void _enviarMensaje() {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) return;

    final mensaje = MensajeModel(
      id: const Uuid().v4(),
      texto: texto,
      remitenteId: usuario.id,
      creadoEn: DateTime.now(),
    );

    ref.read(chatRepositoryProvider).enviarMensaje(widget.chatId, mensaje);
    _mensajeController.clear();
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
              error: (e, st) => Center(child: Text('Error: $e')),
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
                      onPressed: _enviarMensaje,
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
