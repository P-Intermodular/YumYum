import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../auth/controllers/auth_controller.dart';
import '../domain/entities/conversacion_model.dart';
import '../providers/chat_providers.dart';

/// Pantalla que muestra la bandeja de conversaciones del usuario, con
/// buscador, filtros y un layout compacto inspirado en el prototipo
/// `prototipo-figma/src/app/components/yum/screens-b.tsx#L392-L562`.
class ListaChatsScreen extends ConsumerStatefulWidget {
  const ListaChatsScreen({super.key});

  @override
  ConsumerState<ListaChatsScreen> createState() => _ListaChatsScreenState();
}

class _ListaChatsScreenState extends ConsumerState<ListaChatsScreen> {
  final _busquedaController = TextEditingController();
  String _query = '';
  _FiltroChats _filtro = _FiltroChats.todos;

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(listaChatsProvider);
    final usuarioId = ref.watch(autenticacionProvider).value?.id;

    return Scaffold(
      body: YumBackground(
        child: SafeArea(
          bottom: false,
          child: chatsAsync.when(
            data: (chats) => _buildContenido(chats, usuarioId),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(mensajeError(e))),
          ),
        ),
      ),
    );
  }

  Widget _buildContenido(List<ConversacionModel> chats, String? usuarioId) {
    final activos = chats.where(_esActiva).length;
    final noLeidosTotal = chats.fold<int>(
      0,
      (acc, c) => acc + (c.mensajesNoLeidos > 0 ? 1 : 0),
    );

    final filtrados = _aplicarFiltros(chats);

    return Column(
      children: [
        _Header(conversacionesActivas: activos),
        const SizedBox(height: 12),
        _Buscador(
          controller: _busquedaController,
          onChanged: (valor) => setState(() => _query = valor),
        ),
        const SizedBox(height: 12),
        _BarraChips(
          seleccionado: _filtro,
          noLeidosCount: noLeidosTotal,
          activosCount: activos,
          onChanged: (filtro) => setState(() => _filtro = filtro),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filtrados.isEmpty
              ? _MensajeVacio(
                  texto: _textoVacio(chats.isEmpty),
                )
              : _ListaConversaciones(
                  chats: filtrados,
                  usuarioId: usuarioId,
                ),
        ),
      ],
    );
  }

  /// Una conversación se considera "activa" cuando tiene transacción ya
  /// creada y todavía no ha sido completada/cancelada/reportada.
  bool _esActiva(ConversacionModel chat) {
    if (chat.transaccionId == null) return false;
    final estado = chat.estadoTransaccion;
    return estado == EstadoTransaccion.pendiente ||
        estado == EstadoTransaccion.aceptada;
  }

  List<ConversacionModel> _aplicarFiltros(List<ConversacionModel> chats) {
    Iterable<ConversacionModel> resultado = chats;

    switch (_filtro) {
      case _FiltroChats.todos:
        break;
      case _FiltroChats.noLeidos:
        resultado = resultado.where((c) => c.mensajesNoLeidos > 0);
        break;
      case _FiltroChats.activos:
        resultado = resultado.where(_esActiva);
        break;
    }

    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      resultado = resultado.where((c) {
        final nombre = c.participante.nombre.toLowerCase();
        final plato = c.producto?.titulo.toLowerCase() ?? '';
        return nombre.contains(query) || plato.contains(query);
      });
    }

    return resultado.toList();
  }

  String _textoVacio(bool sinChats) {
    if (sinChats) return 'No tienes mensajes todavía.';
    if (_query.isNotEmpty) {
      return 'No encontramos chats que coincidan con "${_query.trim()}".';
    }
    return switch (_filtro) {
      _FiltroChats.todos => 'No tienes mensajes todavía.',
      _FiltroChats.noLeidos => 'Estás al día con tus mensajes.',
      _FiltroChats.activos =>
        'No tienes pedidos en curso. Cuando aceptes una solicitud aparecerá aquí.',
    };
  }
}

enum _FiltroChats { todos, noLeidos, activos }

// ─────────────────────────────────────────────────────────────────────────────
// Header con contador

class _Header extends StatelessWidget {
  final int conversacionesActivas;

  const _Header({required this.conversacionesActivas});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final subtitulo = conversacionesActivas == 0
        ? 'Sin pedidos en curso'
        : conversacionesActivas == 1
            ? '1 conversación activa'
            : '$conversacionesActivas conversaciones activas';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitulo,
            style: TextStyle(color: colors.inkSoft, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            'Mensajes',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Buscador

class _Buscador extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _Buscador({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 18, color: colors.inkSoft),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                // Forzamos todos los estados del decorador a sin borde para
                // que el borde del Container exterior no se duplique con el
                // del tema global del TextField (enabled/focused/disabled).
                decoration: InputDecoration(
                  hintText: 'Busca por vecino o plato…',
                  hintStyle: TextStyle(color: colors.inkSoft, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(color: colors.ink, fontSize: 14),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: Icon(Icons.close_rounded, size: 18, color: colors.inkSoft),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chips de filtro

class _BarraChips extends StatelessWidget {
  final _FiltroChats seleccionado;
  final int noLeidosCount;
  final int activosCount;
  final ValueChanged<_FiltroChats> onChanged;

  const _BarraChips({
    required this.seleccionado,
    required this.noLeidosCount,
    required this.activosCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _ChipFiltro(
            etiqueta: 'Todos',
            seleccionado: seleccionado == _FiltroChats.todos,
            onTap: () => onChanged(_FiltroChats.todos),
          ),
          const SizedBox(width: 8),
          _ChipFiltro(
            etiqueta: noLeidosCount > 0
                ? 'No leídos · $noLeidosCount'
                : 'No leídos',
            seleccionado: seleccionado == _FiltroChats.noLeidos,
            onTap: () => onChanged(_FiltroChats.noLeidos),
          ),
          const SizedBox(width: 8),
          _ChipFiltro(
            etiqueta:
                activosCount > 0 ? 'Activos · $activosCount' : 'Activos',
            seleccionado: seleccionado == _FiltroChats.activos,
            onTap: () => onChanged(_FiltroChats.activos),
          ),
        ],
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipFiltro({
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: seleccionado ? colors.ink : colors.paper,
            border: Border.all(
              color: seleccionado ? colors.ink : colors.line,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            etiqueta,
            style: TextStyle(
              color: seleccionado ? colors.paper : colors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista en un único contenedor con divisores entre items

class _ListaConversaciones extends StatelessWidget {
  final List<ConversacionModel> chats;
  final String? usuarioId;

  const _ListaConversaciones({required this.chats, required this.usuarioId});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.paper,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              for (var i = 0; i < chats.length; i++) ...[
                _ItemChat(chat: chats[i], usuarioId: usuarioId),
                if (i < chats.length - 1)
                  Divider(height: 1, thickness: 1, color: colors.line),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item de la lista (compacto, plato terracotta, check-check)

class _ItemChat extends StatelessWidget {
  final ConversacionModel chat;
  final String? usuarioId;

  const _ItemChat({required this.chat, required this.usuarioId});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final tieneNoLeidos = chat.mensajesNoLeidos > 0;
    final ultimo = chat.ultimoMensaje;
    final ultimoEsMio =
        ultimo != null && usuarioId != null && ultimo.remitenteId == usuarioId;
    final ultimoLeidoPorOtro = ultimoEsMio && ultimo.leidoEn != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(RutasApp.chat(chat.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AvatarUsuario(
                nombre: chat.participante.nombre,
                identificadorColor: chat.participante.id,
                urlImagen: chat.participante.urlImagenPerfil,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fila 1: nombre + hora a la derecha
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.participante.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (ultimo != null)
                          Text(
                            _formatearHora(ultimo.creadoEn),
                            style: TextStyle(
                              fontSize: 11,
                              color: tieneNoLeidos
                                  ? colors.terracottaDeep
                                  : colors.inkSoft,
                              fontWeight: tieneNoLeidos
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    if (chat.producto != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        chat.producto!.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.terracottaDeep,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    // Fila 3: check-check + último + badge unread
                    Row(
                      children: [
                        if (ultimoEsMio) ...[
                          Icon(
                            Icons.done_all_rounded,
                            size: 14,
                            color: ultimoLeidoPorOtro
                                ? colors.olive
                                : colors.inkSoft,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            ultimo?.texto ?? 'Chat iniciado',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: tieneNoLeidos
                                  ? colors.ink
                                  : colors.inkSoft,
                              fontWeight: tieneNoLeidos
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (tieneNoLeidos) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            height: 20,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.terracotta,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${chat.mensajesNoLeidos}',
                              style: TextStyle(
                                color: colors.paper,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formatea la hora de forma humana: hoy → HH:mm, ayer → "Ayer", esta
  /// semana → nombre del día, antes → dd/MM.
  String _formatearHora(DateTime fecha) {
    final ahora = DateTime.now();
    final fechaSolo = DateTime(fecha.year, fecha.month, fecha.day);
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ayer = hoy.subtract(const Duration(days: 1));

    if (fechaSolo == hoy) return DateFormat('HH:mm').format(fecha);
    if (fechaSolo == ayer) return 'Ayer';

    final diasDesde = hoy.difference(fechaSolo).inDays;
    if (diasDesde < 7) {
      // Lun, Mar, Mie...
      return toBeginningOfSentenceCase(
            DateFormat.E('es').format(fecha),
          ) ??
          DateFormat.E('es').format(fecha);
    }
    return DateFormat('dd/MM').format(fecha);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado vacío

class _MensajeVacio extends StatelessWidget {
  final String texto;

  const _MensajeVacio({required this.texto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.inkSoft, fontSize: 14),
        ),
      ),
    );
  }
}
