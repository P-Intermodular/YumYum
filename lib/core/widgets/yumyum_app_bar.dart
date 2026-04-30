import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/rutas_app.dart';
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
    const colorCabecera = Color(0xFF1F4A5B);
    
    // Solo escuchamos el provider si el botón se va a mostrar
    final noLeidas = mostrarBotonNotificaciones
        ? ref.watch(contadorNotificacionesNoLeidasProvider)
        : 0;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: mostrarBotonVolver
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: colorCabecera, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Text(
        titulo,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: colorCabecera,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFFD5ECD4), // Soft sage/mint green
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        ...?accionesExtra,
        if (mostrarBotonNotificaciones)
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: colorCabecera),
                if (noLeidas > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        noLeidas > 99 ? '99+' : noLeidas.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
                const Icon(Icons.person_outline_rounded, color: colorCabecera),
            onPressed: () => context.push(RutasApp.perfil),
          ),
      ],
    );
  }
}
