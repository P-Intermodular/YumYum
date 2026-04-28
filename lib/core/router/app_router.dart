import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final refresh = ref.watch(_appRouterRefreshProvider);

  return GoRouter(
    initialLocation: RutasApp.iniciarSesion,
    refreshListenable: refresh,
    redirect: (context, state) {
      final autenticacion = ref.read(autenticacionProvider);

      return resolverRedireccionAutenticacion(
        uri: state.uri,
        autenticacionCargando: autenticacion.isLoading,
        autenticado: autenticacion.valueOrNull != null,
        enRecuperacion: autenticacion.enRecuperacion,
      );
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
          codigo: state.uri.queryParameters['code'],
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

final _appRouterRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final refresh = ValueNotifier(0);

  ref.listen<EstadoAutenticacion>(autenticacionProvider, (previous, next) {
    refresh.value++;
  });

  ref.onDispose(refresh.dispose);
  return refresh;
});

/// Decide la redirección de autenticación sin depender de [GoRouter].
///
/// Es una función pura para poder cubrir los casos delicados de recovery en
/// tests sin levantar toda la navegación de la aplicación.
String? resolverRedireccionAutenticacion({
  required Uri uri,
  required bool autenticacionCargando,
  required bool autenticado,
  required bool enRecuperacion,
}) {
  final path = uri.path;
  final esRutaRestablecer = path == RutasApp.restablecerPassword;

  if (_tieneParametrosRecuperacion(uri) && !esRutaRestablecer) {
    return _rutaRestablecerPasswordConQuery(uri);
  }

  // El formulario de recovery siempre gana sobre cualquier sesión temporal que
  // Supabase haya abierto al validar el enlace.
  if (esRutaRestablecer) {
    return null;
  }

  if (autenticacionCargando) return null;

  if (enRecuperacion) {
    return RutasApp.restablecerPassword;
  }

  final rutaPublica = RutasApp.esRutaPublica(path);

  if (!autenticado && !rutaPublica) {
    return RutasApp.iniciarSesion;
  }

  if (autenticado && rutaPublica) {
    return RutasApp.inicio;
  }

  return null;
}

bool _tieneParametrosRecuperacion(Uri uri) {
  final code = uri.queryParameters['code'];
  final tokenHash = uri.queryParameters['token_hash'];
  final tipo = uri.queryParameters['type'];

  return (code != null && code.isNotEmpty) ||
      (tipo == 'recovery' && tokenHash != null && tokenHash.isNotEmpty);
}

String _rutaRestablecerPasswordConQuery(Uri uri) {
  final query = Uri(queryParameters: uri.queryParameters).query;
  if (query.isEmpty) return RutasApp.restablecerPassword;
  return '${RutasApp.restablecerPassword}?$query';
}
