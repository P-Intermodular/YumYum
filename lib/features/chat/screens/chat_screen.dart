import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/ui/yum_app_bar.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/domain/entities/usuario_model.dart';
import '../controllers/chat_controller.dart';
import '../data/typing_indicator_controller.dart';
import '../domain/entities/conversacion_model.dart';
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
  final ScrollController _scrollController = ScrollController();

  /// Distancia en pixels desde el fondo dentro de la cual se considera que
  /// el usuario "esta al final" y por tanto auto-scrolleamos al recibir.
  /// Si esta mas arriba (leyendo historial), no le movemos la vista.
  static const double _umbralCercaDelFondoPx = 240;

  /// Marca puesta justo despues de enviar para forzar el siguiente
  /// auto-scroll aunque el usuario este leyendo historial. WhatsApp tambien
  /// se va al fondo cuando es uno mismo quien escribe.
  bool _forzarScrollSiguiente = false;

  TypingIndicatorController? _typingController;

  @override
  void initState() {
    super.initState();
    _marcarMensajesComoLeidos();
    _inicializarTyping();
  }

  /// Inicializa el canal Realtime de typing para esta conversación. Lo hacemos
  /// en initState (no en build) para crear el canal una sola vez.
  void _inicializarTyping() {
    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) return;
    final controller = TypingIndicatorController(
      client: ref.read(supabaseClientProvider),
      conversacionId: widget.chatId,
      miId: usuario.id,
    );
    controller.addListener(_onTypingCambio);
    controller.start();
    _typingController = controller;
  }

  void _onTypingCambio() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _marcarMensajesComoLeidos() async {
    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) return;
    try {
      await ref.read(chatRepositoryProvider).marcarMensajesLeidos(widget.chatId, usuario.id);
    } catch (e) {
      debugPrint('Error al marcar mensajes como leídos: $e');
    }
  }

  @override
  void dispose() {
    _typingController?.removeListener(_onTypingCambio);
    _typingController?.dispose();
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    try {
      // Marcamos antes del await para que el evento del stream que llega tras
      // la insercion ya encuentre la marca activa y fuerce el scroll.
      _forzarScrollSiguiente = true;
      await ref
          .read(chatControllerProvider.notifier)
          .enviarMensaje(widget.chatId, texto);
      _mensajeController.clear();
      // Tras enviar, permitimos un nuevo broadcast de typing inmediato para
      // que la siguiente palabra dispare el indicador en el otro lado.
      _typingController?.resetearTrasEnvio();
    } catch (error) {
      _forzarScrollSiguiente = false;
      if (mounted) mostrarError(context, error);
    }
  }

  /// Auto-scroll estilo WhatsApp: salta al fondo cuando recibes/envias un
  /// mensaje y o (a) lo acabas de mandar tu, o (b) ya estabas pegado al
  /// fondo. Si estabas leyendo historial, no te molestamos.
  void _autoScrollAlRecibirMensaje() {
    final forzar = _forzarScrollSiguiente;
    _forzarScrollSiguiente = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      // Con reverse:true, pixels=0 corresponde al fondo (mensaje mas reciente).
      final cercaDelFondo =
          _scrollController.position.pixels < _umbralCercaDelFondoPx;
      if (!forzar && !cercaDelFondo) return;

      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Reaccionamos a los cambios del stream para auto-scroll al fondo cuando
    // crece la lista (envio propio o recepcion). El listener corre fuera del
    // build, asi que no programa setState durante la fase de pintado.
    ref.listen<AsyncValue<List<MensajeModel>>>(
      mensajesProvider(widget.chatId),
      (previa, actual) {
        final cantidadAnterior = previa?.value?.length ?? 0;
        final cantidadActual = actual.value?.length ?? 0;
        if (cantidadActual > cantidadAnterior) {
          _autoScrollAlRecibirMensaje();
        }
      },
    );

    final mensajesAsync = ref.watch(mensajesProvider(widget.chatId));
    final usuarioActual = ref.watch(autenticacionProvider).value;
    final chats = ref.watch(listaChatsProvider).value ?? [];
    final chatActual = chats.where((c) => c.id == widget.chatId).firstOrNull;
    final nombreParticipante = chatActual?.participante.nombre ?? 'Chat';

    final colors = context.yumColors;

    return Scaffold(
      appBar: YumAppBar(
        title: nombreParticipante,
        showBack: true,
        action: chatActual != null
            ? _AvatarParticipanteAccion(participante: chatActual.participante)
            : null,
      ),
      body: YumBackground(
        child: Column(
          children: [
            if (chatActual?.producto != null)
              _BannerProducto(conversacion: chatActual!),
            Expanded(
              child: mensajesAsync.when(
                data: (mensajesBase) {
                  // Revertimos la lista para mostrar el mas reciente abajo (en UI reverse: true)
                  final mensajes = mensajesBase.reversed.toList();

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      top: 16,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    reverse: true,
                    itemCount: mensajes.length,
                    itemBuilder: (context, index) {
                      final mensaje = mensajes[index];
                      final esMio = mensaje.remitenteId == usuarioActual?.id;

                      // Lógica para mostrar separadores de fecha reales
                      bool mostrarSeparadorFecha = false;
                      if (index == mensajes.length - 1) {
                        // Es el primer mensaje histórico de la lista (el más antiguo)
                        mostrarSeparadorFecha = true;
                      } else {
                        // Comparar con el mensaje anterior cronológicamente (que en la lista invertida es index + 1)
                        final mensajeAnterior = mensajes[index + 1];
                        final fechaActual = DateTime(mensaje.creadoEn.year, mensaje.creadoEn.month, mensaje.creadoEn.day);
                        final fechaAnterior = DateTime(mensajeAnterior.creadoEn.year, mensajeAnterior.creadoEn.month, mensajeAnterior.creadoEn.day);
                        if (fechaActual != fechaAnterior) {
                          mostrarSeparadorFecha = true;
                        }
                      }

                      Widget burbuja = Align(
                        alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: esMio ? colors.terracotta : colors.paper,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: esMio ? const Radius.circular(4) : null,
                              bottomLeft: !esMio ? const Radius.circular(4) : null,
                            ),
                            border: esMio ? null : Border.all(color: colors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mensaje.texto,
                                style: TextStyle(
                                  color: esMio ? colors.paper : colors.ink,
                                  fontSize: 15,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('HH:mm').format(mensaje.creadoEn),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: esMio ? colors.paper.withValues(alpha: 0.8) : colors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (mostrarSeparadorFecha) {
                        String textoFecha;
                        final ahora = DateTime.now();
                        final fechaMensaje = DateTime(mensaje.creadoEn.year, mensaje.creadoEn.month, mensaje.creadoEn.day);
                        final fechaHoy = DateTime(ahora.year, ahora.month, ahora.day);
                        final fechaAyer = fechaHoy.subtract(const Duration(days: 1));

                        if (fechaMensaje == fechaHoy) {
                          textoFecha = 'Hoy';
                        } else if (fechaMensaje == fechaAyer) {
                          textoFecha = 'Ayer';
                        } else {
                          textoFecha = DateFormat('dd MMM yyyy').format(mensaje.creadoEn);
                        }

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  textoFecha,
                                  style: TextStyle(color: colors.inkSoft, fontSize: 13),
                                ),
                              ),
                            ),
                            burbuja,
                          ],
                        );
                      }

                      return burbuja;
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text(mensajeError(e))),
              ),
            ),
            // Indicador "escribiendo…" del otro participante.
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.bottomLeft,
              curve: Curves.easeOut,
              child: _typingController?.escribiendo == true
                  ? const _IndicadorEscribiendo()
                  : const SizedBox.shrink(),
            ),
            // Input Area
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: colors.paper,
                border: Border(top: BorderSide(color: colors.line)),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file_rounded, color: colors.inkSoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.cream,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _mensajeController,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onChanged: (_) => _typingController?.notificarTecleo(),
                        onSubmitted: (_) => _enviarMensaje(),
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: TextStyle(color: colors.inkSoft),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          suffixIcon: Icon(Icons.sentiment_satisfied_alt, color: colors.inkSoft),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _enviarMensaje,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.terracotta,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.send_rounded, color: colors.paper, size: 20),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// Banner pinned bajo el AppBar con el plato negociado en la conversación.
///
/// Replica del patrón figma (`screens-b.tsx#L104-L111`): miniatura del plato +
/// título + precio · código de pedido. Tap → detalle del pedido (transacción
/// si ya está aceptada, solicitud en otro caso). El producto detalle queda
/// como fallback para conversaciones sin solicitud.
class _BannerProducto extends StatelessWidget {
  final ConversacionModel conversacion;

  const _BannerProducto({required this.conversacion});

  /// Decide a dónde llevar al usuario al pulsar el banner.
  ///
  /// El chat trata de un pedido concreto, no de la ficha pública del producto.
  /// Si la solicitud ya fue aceptada vamos al detalle de transacción; si está
  /// en cualquier otro estado (pendiente, denegada, cancelada) vamos a la
  /// pantalla de pedido por solicitud, que pinta su timeline correspondiente.
  String _resolverDestino() {
    final transaccionId = conversacion.transaccionId;
    if (transaccionId != null) return RutasApp.transaccionDetalle(transaccionId);

    final solicitudId = conversacion.solicitudId;
    if (solicitudId != null) return RutasApp.pedidoPorSolicitud(solicitudId);

    return RutasApp.productoDetalle(conversacion.producto!.id);
  }

  /// Código humano del pedido (últimos 6 caracteres del id de transacción /
  /// solicitud). Si por algún motivo no hay ninguno, cae al id del producto
  /// para no romper el render.
  String _resolverCodigo() {
    final fuente = conversacion.transaccionId ??
        conversacion.solicitudId ??
        conversacion.producto!.id;
    return fuente.length >= 6
        ? fuente.substring(fuente.length - 6).toUpperCase()
        : fuente.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final producto = conversacion.producto!;
    final precioTexto = producto.tipoOferta == 'intercambio' || producto.precio == null
        ? 'Intercambio'
        : '${producto.precio!.toStringAsFixed(2)} €';
    final codigoCorto = _resolverCodigo();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(_resolverDestino()),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.paper,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: producto.urlImagen.isNotEmpty
                        ? Image.network(
                            producto.urlImagen,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: colors.cream2),
                          )
                        : Container(color: colors.cream2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        producto.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$precioTexto · Pedido #$codigoCorto',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 18, color: colors.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Burbuja del lado izquierdo con tres puntitos animados que aparece cuando
/// la otra persona está tecleando (Realtime broadcast desde el otro cliente).
class _IndicadorEscribiendo extends StatefulWidget {
  const _IndicadorEscribiendo();

  @override
  State<_IndicadorEscribiendo> createState() => _IndicadorEscribiendoState();
}

class _IndicadorEscribiendoState extends State<_IndicadorEscribiendo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animacion;

  @override
  void initState() {
    super.initState();
    _animacion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.paper,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomLeft: const Radius.circular(4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                child: AnimatedBuilder(
                  animation: _animacion,
                  builder: (context, _) {
                    // Cada punto sube/baja 4px desfasado 0,15s respecto al
                    // anterior para crear un loop tipo "bouncing dots".
                    final fase = (_animacion.value - i * 0.15) % 1.0;
                    final dy = fase < 0.5 ? -4 * (fase / 0.5) : -4 * (1 - (fase - 0.5) / 0.5);
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.inkSoft,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Avatar pequeño de la contraparte en el AppBar; tap → su perfil ajeno.
class _AvatarParticipanteAccion extends StatelessWidget {
  final UsuarioModel participante;

  const _AvatarParticipanteAccion({required this.participante});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(RutasApp.perfilUsuario(participante.id)),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: AvatarUsuario(
          nombre: participante.nombre,
          identificadorColor: participante.id,
          urlImagen: participante.urlImagenPerfil,
          radius: 16,
        ),
      ),
    );
  }
}
