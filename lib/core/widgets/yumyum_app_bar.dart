import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/rutas_app.dart';
import '../theme/yum_colors.dart';
import '../../features/notificaciones/providers/notificacion_providers.dart';

/// AppBar reutilizable para las pantallas de YumYum.
///
/// Centraliza la navegación secundaria y mantiene el mismo lenguaje visual en
/// inicio, detalle, perfil y el resto de secciones principales.
class YumYumAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String titulo;
  final bool mostrarBotonPerfil;
  final bool mostrarBotonNotificaciones;
  final bool mostrarBotonVolver;
  final List<Widget>? accionesExtra;

  const YumYumAppBar({
    super.key,
    required this.titulo,
    this.mostrarBotonPerfil = true,
    this.mostrarBotonNotificaciones = false,
    this.mostrarBotonVolver = false,
    this.accionesExtra,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;

    // Solo escuchamos el provider si el botón se va a mostrar
    final noLeidas = mostrarBotonNotificaciones
        ? ref.watch(contadorNotificacionesNoLeidasProvider)
        : 0;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: mostrarBotonVolver
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: colors.ink, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colors.ink,
          fontSize: 18,
          letterSpacing: 0.2,
        ),
      ),
      centerTitle: true,
      backgroundColor: colors.cream,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        ...?accionesExtra,
        if (mostrarBotonNotificaciones)
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_none_rounded, color: colors.ink),
                if (noLeidas > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.terracotta,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.cream, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          noLeidas > 99 ? '99+' : noLeidas.toString(),
                          style: TextStyle(
                            color: colors.paper,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.push(RutasApp.notificaciones),
          ),
        if (mostrarBotonPerfil)
          IconButton(
            icon:
                Icon(Icons.person_outline_rounded, color: colors.ink),
            onPressed: () => context.push(RutasApp.perfil),
          ),
      ],
    );
  }
}
