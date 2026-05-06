import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../auth/controllers/auth_controller.dart';

/// Categorías de notificación disponibles. Las claves coinciden con las
/// que viajan en la columna `preferencias_notificaciones` (jsonb) y con
/// las que el helper `notificacion_providers` usa para mapear cada tipo
/// de la tabla `notificaciones` a su categoría.
const _categorias = <_Categoria>[
  _Categoria(
    clave: 'pedidos',
    titulo: 'Pedidos y solicitudes',
    descripcion: 'Solicitudes recibidas, aceptadas, canceladas y entregas.',
    icono: Icons.shopping_basket_outlined,
  ),
  _Categoria(
    clave: 'mensajes',
    titulo: 'Mensajes',
    descripcion: 'Cuando un vecino te envía un mensaje en el chat.',
    icono: Icons.chat_bubble_outline_rounded,
  ),
  _Categoria(
    clave: 'valoraciones',
    titulo: 'Valoraciones',
    descripcion: 'Cuando alguien te valora tras una entrega.',
    icono: Icons.star_outline_rounded,
  ),
];

/// Pantalla que controla qué tipos de notificación quiere recibir el
/// usuario. Cada toggle persiste de inmediato (UI optimista con rollback
/// si falla la red), siguiendo el patrón iOS/Android — sin botón Guardar.
class PreferenciasNotificacionesScreen extends ConsumerStatefulWidget {
  const PreferenciasNotificacionesScreen({super.key});

  @override
  ConsumerState<PreferenciasNotificacionesScreen> createState() =>
      _PreferenciasNotificacionesScreenState();
}

class _PreferenciasNotificacionesScreenState
    extends ConsumerState<PreferenciasNotificacionesScreen> {
  /// Snapshot local del map. Se inicializa desde el usuario y se va
  /// actualizando con cada toggle. La fuente real de verdad sigue siendo
  /// `autenticacionProvider`, pero usamos esta copia para la UI optimista.
  late Map<String, bool> _local;

  /// Toggles concretos que están guardándose en este momento. Sirve para
  /// deshabilitarlos visualmente y evitar dobles taps mientras va la red.
  final Set<String> _guardando = {};

  @override
  void initState() {
    super.initState();
    final usuario = ref.read(autenticacionProvider).value;
    _local = {
      for (final cat in _categorias)
        cat.clave: usuario?.puedeRecibir(cat.clave) ?? true,
    };
  }

  Future<void> _alternar(String clave, bool valorPrevio) async {
    final nuevoValor = !valorPrevio;
    setState(() {
      _local[clave] = nuevoValor;
      _guardando.add(clave);
    });

    try {
      await ref
          .read(autenticacionProvider.notifier)
          .actualizarPreferenciasNotificaciones(Map<String, bool>.from(_local));
    } catch (error) {
      // Rollback en UI si falla.
      if (!mounted) return;
      setState(() => _local[clave] = valorPrevio);
      mostrarError(context, error);
    } finally {
      if (mounted) setState(() => _guardando.remove(clave));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    return Scaffold(
      body: YumBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notificaciones',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontSize: 26,
                                height: 1.1,
                                fontWeight: FontWeight.w600,
                                color: colors.ink,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Elige qué quieres recibir en la bandeja.',
                          style: TextStyle(color: colors.inkSoft, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.paper,
                      border: Border.all(color: colors.line),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < _categorias.length; i++) ...[
                          _TileSwitch(
                            categoria: _categorias[i],
                            activo: _local[_categorias[i].clave] ?? true,
                            cargando: _guardando.contains(
                              _categorias[i].clave,
                            ),
                            onCambio: () => _alternar(
                              _categorias[i].clave,
                              _local[_categorias[i].clave] ?? true,
                            ),
                            ultimo: i == _categorias.length - 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tu bandeja se filtra automáticamente según estas '
                    'preferencias. Las notificaciones siguen llegando al '
                    'sistema, pero las ocultas no se muestran ni cuentan '
                    'como no leídas.',
                    style: TextStyle(
                      color: colors.inkSoft,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _BotonAtras(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Categoria {
  final String clave;
  final String titulo;
  final String descripcion;
  final IconData icono;

  const _Categoria({
    required this.clave,
    required this.titulo,
    required this.descripcion,
    required this.icono,
  });
}

class _TileSwitch extends StatelessWidget {
  final _Categoria categoria;
  final bool activo;
  final bool cargando;
  final VoidCallback onCambio;
  final bool ultimo;

  const _TileSwitch({
    required this.categoria,
    required this.activo,
    required this.cargando,
    required this.onCambio,
    required this.ultimo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Container(
      decoration: BoxDecoration(
        border: ultimo ? null : Border(bottom: BorderSide(color: colors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.cream2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(categoria.icono, size: 18, color: colors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoria.titulo,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  categoria.descripcion,
                  style: TextStyle(
                    color: colors.inkSoft,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: activo,
            activeThumbColor: colors.terracotta,
            onChanged: cargando ? null : (_) => onCambio(),
          ),
        ],
      ),
    );
  }
}

class _BotonAtras extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Material(
      color: colors.paper,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go(RutasApp.ajustes);
          }
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.paper,
            shape: BoxShape.circle,
            border: Border.all(color: colors.line),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: colors.ink,
          ),
        ),
      ),
    );
  }
}
