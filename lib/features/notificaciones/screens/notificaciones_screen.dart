import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/format/tiempo_relativo.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../domain/entities/notificacion_model.dart';
import '../providers/notificacion_providers.dart';

/// Pantalla del centro de notificaciones del usuario.
///
/// Muestra las notificaciones agrupadas por antigüedad (Hoy / Esta semana /
/// Antes), con el lenguaje visual de la app: paper, hairlines, tintes
/// semánticos sobre la paleta YumColors. Al entrar marca todas como leídas;
/// las que lleguen por realtime mientras la pantalla está abierta conservan
/// el punto terracotta hasta la siguiente visita.
class NotificacionesScreen extends ConsumerStatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  ConsumerState<NotificacionesScreen> createState() =>
      _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen> {
  /// Ids ya animados; evita reanimar la lista cuando llega una notificación
  /// nueva por realtime.
  final Set<String> _yaAnimados = <String>{};

  @override
  void initState() {
    super.initState();
    _marcarTodasComoLeidas();
  }

  Future<void> _marcarTodasComoLeidas() async {
    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) return;
    try {
      await ref
          .read(notificacionRepositoryProvider)
          .marcarTodasLeidas(usuario.id);
    } catch (_) {
      // Fallo silencioso: el badge se actualizará por el stream.
    }
  }

  void _abrirNotificacion(NotificacionModel n) {
    final datos = n.datos;
    if (datos['conversacion_id'] is String) {
      context.push(RutasApp.chat(datos['conversacion_id'] as String));
      return;
    }
    if (datos['transaccion_id'] is String) {
      context.push(
        RutasApp.transaccionDetalle(datos['transaccion_id'] as String),
      );
      return;
    }
    if (datos['producto_id'] is String) {
      context.push(RutasApp.productoDetalle(datos['producto_id'] as String));
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
      ),
      body: YumBackground(
        child: notificacionesAsync.when(
          data: _buildLista,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildEstadoError(),
        ),
      ),
    );
  }

  Widget _buildLista(List<NotificacionModel> notificaciones) {
    if (notificaciones.isEmpty) return _buildEstadoVacio();

    final noLeidas = notificaciones.where((n) => n.noLeida).length;
    final grupos = _agruparPorFecha(notificaciones);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _buildHeaderContador(noLeidas),
        for (final entry in grupos.entries) ...[
          const SizedBox(height: 18),
          _buildHeaderGrupo(entry.key),
          const SizedBox(height: 10),
          _buildCardGrupo(entry.value),
        ],
      ],
    );
  }

  Widget _buildHeaderContador(int noLeidas) {
    final colors = context.yumColors;
    final alDia = noLeidas == 0;
    final texto = alDia ? 'Estás al día' : '$noLeidas sin leer';
    final color = alDia ? colors.oliveDeep : colors.terracottaDeep;
    final icono = alDia
        ? Icons.check_circle_outline_rounded
        : Icons.fiber_manual_record_rounded;

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 2),
      child: Row(
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: alDia ? FontWeight.w600 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderGrupo(String etiqueta) {
    final colors = context.yumColors;
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        etiqueta.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          color: colors.inkSoft,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCardGrupo(List<NotificacionModel> items) {
    final colors = context.yumColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: colors.line,
                indent: 64,
              ),
            _buildItemAnimado(items[i], i),
          ],
        ],
      ),
    );
  }

  Widget _buildItemAnimado(NotificacionModel n, int indiceEnGrupo) {
    final esPrimeraVez = !_yaAnimados.contains(n.id);
    if (esPrimeraVez) _yaAnimados.add(n.id);

    final item = _ItemNotificacion(
      notificacion: n,
      onTap: () => _abrirNotificacion(n),
    );

    if (!esPrimeraVez) return item;

    // Stagger sutil al primer pintado: fade + slide breve.
    return _AparicionStagger(
      delay: Duration(milliseconds: 40 * indiceEnGrupo.clamp(0, 6)),
      child: item,
    );
  }

  Widget _buildEstadoVacio() {
    final colors = context.yumColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.line,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco_outlined, size: 36, color: colors.olive),
              const SizedBox(height: 12),
              Text(
                'Nada por aquí… aún',
                style:
                    Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          color: colors.ink,
                        ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Cuando un vecino te escriba o haya novedad cerca, te avisaremos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.inkSoft,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoError() {
    final colors = context.yumColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: colors.terracottaDeep,
              ),
              const SizedBox(height: 10),
              Text(
                'No pudimos cargar tus notificaciones',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      color: colors.ink,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Comprueba la conexión y vuelve a intentarlo en un momento.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.inkSoft,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bucketiza por días naturales locales: Hoy / Esta semana / Antes.
  /// Mantiene el orden de entrada (ya viene desc por `creado_en`).
  Map<String, List<NotificacionModel>> _agruparPorFecha(
    List<NotificacionModel> notifs,
  ) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioSemana = hoy.subtract(const Duration(days: 6));

    final grupos = <String, List<NotificacionModel>>{
      'Hoy': [],
      'Esta semana': [],
      'Anteriores': [],
    };

    for (final n in notifs) {
      final dia =
          DateTime(n.creadoEn.year, n.creadoEn.month, n.creadoEn.day);
      if (!dia.isBefore(hoy)) {
        grupos['Hoy']!.add(n);
      } else if (!dia.isBefore(inicioSemana)) {
        grupos['Esta semana']!.add(n);
      } else {
        grupos['Anteriores']!.add(n);
      }
    }

    grupos.removeWhere((_, items) => items.isEmpty);
    return grupos;
  }
}

/// Item individual de notificación con icono semántico, título, hora,
/// cuerpo (line-clamp 2) y punto terracotta cuando está sin leer.
class _ItemNotificacion extends StatelessWidget {
  final NotificacionModel notificacion;
  final VoidCallback onTap;

  const _ItemNotificacion({
    required this.notificacion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final paleta = _paletaParaTipo(notificacion.tipo, colors);
    final noLeida = notificacion.noLeida;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: paleta.fondo,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                _iconoParaTipo(notificacion.tipo),
                size: 18,
                color: paleta.icono,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notificacion.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.ink,
                            fontWeight:
                                noLeida ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatearTiempoRelativo(notificacion.creadoEn),
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                  if (notificacion.contenido.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notificacion.contenido,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.inkSoft,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (noLeida) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: colors.terracotta,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mapeo de tipo de notificación → tinte de marca y color del icono.
class _PaletaTipo {
  final Color fondo;
  final Color icono;
  const _PaletaTipo(this.fondo, this.icono);
}

_PaletaTipo _paletaParaTipo(String tipo, YumColors colors) {
  switch (tipo) {
    case 'solicitud_oferta_creada':
      return _PaletaTipo(
        colors.olive.withValues(alpha: 0.15),
        colors.oliveDeep,
      );
    case 'solicitud_oferta_aceptada':
      return _PaletaTipo(
        colors.terracotta.withValues(alpha: 0.12),
        colors.terracottaDeep,
      );
    case 'solicitud_oferta_denegada':
    case 'solicitud_oferta_auto_denegada':
      return _PaletaTipo(
        colors.mustard.withValues(alpha: 0.22),
        colors.ink,
      );
    case 'solicitud_oferta_cancelada':
    case 'transaccion_cancelada':
      return _PaletaTipo(colors.cream2, colors.inkSoft);
    default:
      return _PaletaTipo(colors.cream2, colors.inkSoft);
  }
}

IconData _iconoParaTipo(String tipo) {
  switch (tipo) {
    case 'solicitud_oferta_creada':
      return Icons.restaurant_outlined;
    case 'solicitud_oferta_aceptada':
      return Icons.check_circle_outline_rounded;
    case 'solicitud_oferta_denegada':
      return Icons.block_rounded;
    case 'solicitud_oferta_auto_denegada':
      return Icons.info_outline_rounded;
    case 'solicitud_oferta_cancelada':
      return Icons.undo_rounded;
    case 'transaccion_cancelada':
      return Icons.error_outline_rounded;
    default:
      return Icons.notifications_none_rounded;
  }
}

/// Pequeño wrapper que aplica un fade+slide al insertarse, una sola vez.
class _AparicionStagger extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AparicionStagger({required this.child, required this.delay});

  @override
  State<_AparicionStagger> createState() => _AparicionStaggerState();
}

class _AparicionStaggerState extends State<_AparicionStagger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacidad;
  late final Animation<Offset> _desplazamiento;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _opacidad = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _desplazamiento = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacidad,
      child: SlideTransition(
        position: _desplazamiento,
        child: widget.child,
      ),
    );
  }
}
