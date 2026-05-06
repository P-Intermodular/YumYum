import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/widgets/ui/boton_ia_global.dart';
import '../../../core/widgets/ui/yum_bottom_nav.dart';

/// Shell principal con la navegación inferior compartida de la app.
class PrincipalScreen extends StatelessWidget {
  final Widget child;

  const PrincipalScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Necesario para el efecto flotante sobre el contenido
      body: Stack(
        children: [
          child,
          // FAB del asistente IA: persistente en todas las pantallas dentro
          // del shell (Inicio, Mapa, Pedidos, Chats, etc.) pero no en
          // login/registro/recuperación, donde no tiene sentido un asistente.
          // Lo elevamos por encima del bottom nav flotante (~96 px de alto).
          const Positioned(
            right: 16,
            bottom: 110,
            child: BotonIAGlobal(),
          ),
        ],
      ),
      bottomNavigationBar: YumBottomNav(
        currentTab: _calculateSelectedTab(context),
        onTabSelected: (tab) => _onTabSelected(tab, context),
      ),
    );
  }

  static YumNavTab _calculateSelectedTab(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(RutasApp.inicio)) return YumNavTab.home;
    if (location.startsWith(RutasApp.mapa)) return YumNavTab.map;
    if (location.startsWith(RutasApp.publicar)) return YumNavTab.publish;
    if (location.startsWith(RutasApp.pedidos)) return YumNavTab.pedidos;
    if (location.startsWith(RutasApp.chats)) return YumNavTab.chats;
    // Perfil ya no tiene tab propia: se accede desde el avatar del feed. No
    // resaltamos ninguna pestaña cuando el usuario está en /perfil.
    return YumNavTab.home;
  }

  void _onTabSelected(YumNavTab tab, BuildContext context) {
    switch (tab) {
      case YumNavTab.home:
        context.go(RutasApp.inicio);
        break;
      case YumNavTab.map:
        context.go(RutasApp.mapa);
        break;
      case YumNavTab.publish:
        context.go(RutasApp.publicar);
        break;
      case YumNavTab.pedidos:
        context.go(RutasApp.pedidos);
        break;
      case YumNavTab.chats:
        context.go(RutasApp.chats);
        break;
    }
  }


}
