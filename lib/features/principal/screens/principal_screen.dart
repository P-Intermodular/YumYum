import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/widgets/ui/yum_bottom_nav.dart';

/// Shell principal con la navegación inferior compartida de la app.
class PrincipalScreen extends StatelessWidget {
  final Widget child;

  const PrincipalScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Necesario para el efecto flotante sobre el contenido
      body: child,
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
    if (location.startsWith(RutasApp.chats)) return YumNavTab.chats;
    // Pedidos pasa a ser una pantalla derivada del perfil; al estar en
    // /pedidos resaltamos la pestaña Perfil para mantener coherencia visual.
    if (location.startsWith(RutasApp.pedidos)) return YumNavTab.profile;
    if (location.startsWith(RutasApp.perfil)) return YumNavTab.profile;
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
      case YumNavTab.chats:
        context.go(RutasApp.chats);
        break;
      case YumNavTab.profile:
        context.go(RutasApp.perfil);
        break;
    }
  }


}
