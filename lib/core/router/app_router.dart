import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/rutas_app.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/inicio_sesion_screen.dart';
import '../../features/auth/screens/registro_screen.dart';
import '../../features/auth/screens/recuperar_password_screen.dart';
import '../../features/auth/screens/restablecer_password_screen.dart';
import '../../features/inicio/screens/inicio_screen.dart';
import '../../features/principal/screens/principal_screen.dart';
import '../../features/mapa/screens/mapa_screen.dart';
import '../../features/chat/screens/lista_chats_screen.dart';
import '../../features/perfil/screens/perfil_screen.dart';
import '../../features/perfil/screens/editar_ubicacion_perfil_screen.dart';
import '../../features/producto/screens/publicar_producto_screen.dart';
import '../../features/producto/screens/detalle_producto_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/pedidos/screens/pedidos_screen.dart';
import '../../features/pedidos/screens/detalle_transaccion_screen.dart';
import '../../features/valoraciones/screens/valorar_transaccion_screen.dart';

/// Expone el [GoRouter] principal de la aplicación.
///
/// El router observa el estado de autenticación para redirigir automáticamente
/// entre las rutas públicas y privadas.
final appRouterProvider = Provider<GoRouter>((ref) {
  final autenticacion = ref.watch(autenticacionProvider);

  return GoRouter(
    initialLocation: RutasApp.iniciarSesion,
    redirect: (context, state) {
      if (autenticacion.isLoading) return null;

      final path = state.uri.path;
      final autenticado = autenticacion.valueOrNull != null;
      final rutaPublica = RutasApp.esRutaPublica(path);
      final esRutaRestablecer = path == RutasApp.restablecerPassword;

      if (esRutaRestablecer) {
        return null;
      }

      // Protege todas las rutas internas mientras la sesión sea anónima.
      if (!autenticado && !rutaPublica) {
        return RutasApp.iniciarSesion;
      }

      // Evita que un usuario autenticado vuelva a login o registro.
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
        path: RutasApp.recuperarPassword,
        builder: (context, state) => const RecuperarPasswordScreen(),
      ),
      GoRoute(
        path: RutasApp.restablecerPassword,
        builder: (context, state) => RestablecerPasswordScreen(
          tokenHash: state.uri.queryParameters['token_hash'],
          tipo: state.uri.queryParameters['type'],
        ),
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
        path: RutasApp.perfilUbicacion,
        builder: (context, state) => const EditarUbicacionPerfilScreen(),
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
      GoRoute(
        path: RutasApp.transaccionParametro,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DetalleTransaccionScreen(transaccionId: id);
        },
      ),
      GoRoute(
        path: RutasApp.valorarParametro,
        builder: (context, state) {
          final id = state.pathParameters['transaccionId']!;
          return ValorarTransaccionScreen(transaccionId: id);
        },
      ),
    ],
  );
});
