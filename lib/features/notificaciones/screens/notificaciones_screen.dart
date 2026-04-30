import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../domain/entities/notificacion_model.dart';
import '../providers/notificacion_providers.dart';

/// Pantalla del centro de notificaciones del usuario.
///
/// Muestra las notificaciones agrupadas visualmente y permite navegar al
/// contexto original (chat, pedido o producto) según el campo `datos`.
class NotificacionesScreen extends ConsumerStatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  ConsumerState<NotificacionesScreen> createState() =>
      _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen> {
  @override
  void initState() {
    super.initState();
    _marcarTodasComoLeidas();
  }

  /// Marca todas las notificaciones pendientes como leídas al entrar.
  Future<void> _marcarTodasComoLeidas() async {
    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) return;
    try {
      await ref
          .read(notificacionRepositoryProvider)
          .marcarTodasLeidas(usuario.id);
    } catch (_) {
      // Fallo silencioso: el badge se actualizará igualmente por realtime.
    }
  }

  /// Navega al recurso contextual según el tipo y los datos de la notificación.
  void _abrirNotificacion(NotificacionModel notificacion) {
    final datos = notificacion.datos;

    if (datos.containsKey('conversacion_id')) {
      context.push(RutasApp.chat(datos['conversacion_id'] as String));
      return;
    }

    if (datos.containsKey('transaccion_id')) {
      context.push(
          RutasApp.transaccionDetalle(datos['transaccion_id'] as String));
      return;
    }

    if (datos.containsKey('producto_id')) {
      context.push(
          RutasApp.productoDetalle(datos['producto_id'] as String));
      return;
    }
  }

  /// Devuelve un icono representativo según el tipo de notificación.
  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'solicitud_oferta_creada':
        return Icons.mail_outline_rounded;
      case 'solicitud_oferta_aceptada':
        return Icons.check_circle_outline_rounded;
      case 'solicitud_oferta_denegada':
        return Icons.cancel_outlined;
      case 'solicitud_oferta_auto_denegada':
        return Icons.info_outline_rounded;
      case 'solicitud_oferta_cancelada':
        return Icons.undo_rounded;
      case 'transaccion_cancelada':
        return Icons.block_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  /// Color de acento para el icono de cada tipo de notificación.
  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'solicitud_oferta_creada':
        return Colors.blue;
      case 'solicitud_oferta_aceptada':
        return Colors.green;
      case 'solicitud_oferta_denegada':
      case 'solicitud_oferta_auto_denegada':
        return Colors.orange;
      case 'solicitud_oferta_cancelada':
      case 'transaccion_cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificacionesAsync = ref.watch(notificacionesProvider);

    return Scaffold(
      appBar: const YumYumAppBar(
        titulo: 'Notificaciones',
        mostrarBotonVolver: true,
        mostrarBotonPerfil: false,
        mostrarBotonNotificaciones: false,
      ),
      body: notificacionesAsync.when(
        data: (notificaciones) {
          if (notificaciones.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notificaciones.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final n = notificaciones[index];
              final color = _colorTipo(n.tipo);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(_iconoTipo(n.tipo), color: color, size: 22),
                ),
                title: Text(
                  n.titulo,
                  style: TextStyle(
                    fontWeight: n.noLeida ? FontWeight.bold : FontWeight.normal,
                    color: const Color(0xFF1F4A5B),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      n.contenido,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatearFecha(n.creadoEn),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                trailing: n.noLeida
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () => _abrirNotificacion(n),
                tileColor: n.noLeida
                    ? Colors.green.withValues(alpha: 0.04)
                    : null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error al cargar notificaciones',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      ),
    );
  }

  /// Formatea la fecha de la notificación de forma legible.
  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) return 'Justo ahora';
    if (diferencia.inMinutes < 60) return 'Hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'Hace ${diferencia.inHours} h';
    if (diferencia.inDays < 7) return 'Hace ${diferencia.inDays} días';
    return DateFormat('d MMM yyyy', 'es').format(fecha);
  }
}
