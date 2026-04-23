import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/rutas_app.dart';

/// AppBar reutilizable para las pantallas de YumYum.
///
/// Centraliza la navegación secundaria y mantiene el mismo lenguaje visual en
/// inicio, detalle, perfil y el resto de secciones principales.
class YumYumAppBar extends StatelessWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context) {
    const colorCabecera = Color(0xFF1F4A5B);

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
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: colorCabecera),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
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
