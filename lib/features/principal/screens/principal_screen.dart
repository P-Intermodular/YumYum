import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';

class PrincipalScreen extends StatelessWidget {
  final Widget child;

  const PrincipalScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (int index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Publicar',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(RutasApp.inicio)) return 0;
    if (location.startsWith(RutasApp.mapa)) return 1;
    if (location.startsWith(RutasApp.publicar)) return 2;
    if (location.startsWith(RutasApp.pedidos)) return 3;
    if (location.startsWith(RutasApp.chats)) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(RutasApp.inicio);
        break;
      case 1:
        context.go(RutasApp.mapa);
        break;
      case 2:
        context.go(RutasApp.publicar);
        break;
      case 3:
        context.go(RutasApp.pedidos);
        break;
      case 4:
        context.go(RutasApp.chats);
        break;
    }
  }
}
