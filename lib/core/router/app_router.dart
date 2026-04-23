import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/rutas_app.dart';
import '../../features/auth/controllers/auth_controller.dart';
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
  final autenticacion = ref.watch(autenticacionProvider);

  return GoRouter(
    initialLocation: RutasApp.iniciarSesion,
    redirect: (context, state) {
      if (autenticacion.isLoading) return null;

      final path = state.uri.path;
      final autenticado = autenticacion.valueOrNull != null;
      final rutaPublica = RutasApp.esRutaPublica(path);

      if (!autenticado && !rutaPublica) {
        return RutasApp.iniciarSesion;
      }

      if (autenticado && rutaPublica) {
        return RutasApp.inicio;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RutasApp.iniciarSesion,
        builder: (context, state) => const InicioSesionScreen(),
      ),
      GoRoute(
        path: RutasApp.aliasLogin,
        redirect: (context, state) => RutasApp.iniciarSesion,
      ),
      GoRoute(
        path: RutasApp.registro,
        builder: (context, state) => const RegistroScreen(),
      ),
      GoRoute(
        path: RutasApp.aliasSignup,
        redirect: (context, state) => RutasApp.registro,
      ),
      ShellRoute(
        builder: (context, state, child) => PrincipalScreen(child: child),
        routes: [
          GoRoute(
            path: RutasApp.inicio,
            builder: (context, state) => const InicioScreen(),
          ),
          GoRoute(
            path: RutasApp.aliasFeed,
            redirect: (context, state) => RutasApp.inicio,
          ),
          GoRoute(
            path: RutasApp.mapa,
            builder: (context, state) => const MapaScreen(),
          ),
          GoRoute(
            path: RutasApp.aliasMap,
            redirect: (context, state) => RutasApp.mapa,
          ),
          GoRoute(
            path: RutasApp.publicar,
            builder: (context, state) => const PublicarProductoScreen(),
          ),
          GoRoute(
            path: RutasApp.aliasAdd,
            redirect: (context, state) => RutasApp.publicar,
          ),
          GoRoute(
            path: RutasApp.pedidos,
            builder: (context, state) => const PedidosScreen(),
          ),
          GoRoute(
            path: RutasApp.aliasOrders,
            redirect: (context, state) => RutasApp.pedidos,
          ),
          GoRoute(
            path: RutasApp.chats,
            builder: (context, state) => const ListaChatsScreen(),
          ),
          GoRoute(
            path: RutasApp.perfil,
            builder: (context, state) => const PerfilScreen(),
          ),
          GoRoute(
            path: RutasApp.aliasProfile,
            redirect: (context, state) => RutasApp.perfil,
          ),
        ],
      ),
      GoRoute(
        path: RutasApp.productoParametro,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DetalleProductoScreen(productoId: id);
        },
      ),
      GoRoute(
        path: RutasApp.aliasProducto,
        redirect: (context, state) =>
            RutasApp.productoDetalle(state.pathParameters['id']!),
      ),
      GoRoute(
        path: RutasApp.chatParametro,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatScreen(chatId: id);
        },
      ),
      GoRoute(
        path: RutasApp.aliasChatRoom,
        redirect: (context, state) =>
            RutasApp.chat(state.pathParameters['id']!),
      ),
    ],
  );
});
