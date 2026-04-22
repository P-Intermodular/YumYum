import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/inicio_sesion_screen.dart';
import '../../features/auth/screens/registro_screen.dart';
import '../../features/inicio/screens/inicio_screen.dart';
import '../../features/principal/screens/principal_screen.dart';
import '../../features/mapa/screens/mapa_screen.dart';
import '../../features/chat/screens/lista_chats_screen.dart';
import '../../features/perfil/screens/perfil_screen.dart';
import '../../features/producto/screens/publicar_producto_screen.dart';
import '../../features/producto/screens/detalle_producto_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/pedidos/screens/pedidos_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/iniciar-sesion',
    routes: [
      GoRoute(
        path: '/iniciar-sesion',
        builder: (context, state) => const InicioSesionScreen(),
      ),
      GoRoute(
        path: '/login',
        redirect: (context, state) => '/iniciar-sesion',
      ),
      GoRoute(
        path: '/registro',
        builder: (context, state) => const RegistroScreen(),
      ),
      GoRoute(
        path: '/signup',
        redirect: (context, state) => '/registro',
      ),
      ShellRoute(
        builder: (context, state, child) => PrincipalScreen(child: child),
        routes: [
          GoRoute(
            path: '/inicio',
            builder: (context, state) => const InicioScreen(),
          ),
          GoRoute(
            path: '/feed',
            redirect: (context, state) => '/inicio',
          ),
          GoRoute(
            path: '/mapa',
            builder: (context, state) => const MapaScreen(),
          ),
          GoRoute(
            path: '/map',
            redirect: (context, state) => '/mapa',
          ),
          GoRoute(
            path: '/publicar',
            builder: (context, state) => const PublicarProductoScreen(),
          ),
          GoRoute(
            path: '/add',
            redirect: (context, state) => '/publicar',
          ),
          GoRoute(
            path: '/pedidos',
            builder: (context, state) => const PedidosScreen(),
          ),
          GoRoute(
            path: '/orders',
            redirect: (context, state) => '/pedidos',
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const ListaChatsScreen(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const PerfilScreen(),
          ),
          GoRoute(
            path: '/profile',
            redirect: (context, state) => '/perfil',
          ),
        ],
      ),
      GoRoute(
        path: '/producto/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DetalleProductoScreen(productoId: id);
        },
      ),
      GoRoute(
        path: '/product/:id',
        redirect: (context, state) =>
            '/producto/${state.pathParameters['id']!}',
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatScreen(chatId: id);
        },
      ),
      GoRoute(
        path: '/chat_room/:id',
        redirect: (context, state) => '/chat/${state.pathParameters['id']!}',
      ),
    ],
  );
});
