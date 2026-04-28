import 'package:flutter_test/flutter_test.dart';
import 'package:yumyum/core/constants/rutas_app.dart';
import 'package:yumyum/core/router/app_router.dart';

void main() {
  group('resolverRedireccionAutenticacion', () {
    test('redirige links recovery con token_hash a restablecer password', () {
      final redirect = resolverRedireccionAutenticacion(
        uri: Uri.parse('/?token_hash=abc&type=recovery'),
        autenticacionCargando: false,
        autenticado: false,
        enRecuperacion: false,
      );

      expect(
        redirect,
        '${RutasApp.restablecerPassword}?token_hash=abc&type=recovery',
      );
    });

    test('redirige links recovery con code PKCE a restablecer password', () {
      final redirect = resolverRedireccionAutenticacion(
        uri: Uri.parse('/?code=pkce-code'),
        autenticacionCargando: false,
        autenticado: false,
        enRecuperacion: false,
      );

      expect(redirect, '${RutasApp.restablecerPassword}?code=pkce-code');
    });

    test('permite siempre la ruta de restablecer password', () {
      final redirect = resolverRedireccionAutenticacion(
        uri: Uri.parse(RutasApp.restablecerPassword),
        autenticacionCargando: false,
        autenticado: true,
        enRecuperacion: true,
      );

      expect(redirect, isNull);
    });

    test('mantiene recovery aunque exista una sesion persistida', () {
      final redirect = resolverRedireccionAutenticacion(
        uri: Uri.parse('${RutasApp.restablecerPassword}?code=pkce-code'),
        autenticacionCargando: false,
        autenticado: true,
        enRecuperacion: false,
      );

      expect(redirect, isNull);
    });

    test('redirige usuarios autenticados fuera de login', () {
      final redirect = resolverRedireccionAutenticacion(
        uri: Uri.parse(RutasApp.iniciarSesion),
        autenticacionCargando: false,
        autenticado: true,
        enRecuperacion: false,
      );

      expect(redirect, RutasApp.inicio);
    });

    test('redirige usuarios anonimos fuera de rutas privadas', () {
      final redirect = resolverRedireccionAutenticacion(
        uri: Uri.parse(RutasApp.pedidos),
        autenticacionCargando: false,
        autenticado: false,
        enRecuperacion: false,
      );

      expect(redirect, RutasApp.iniciarSesion);
    });

    test('prioriza recovery activo sobre rutas internas', () {
      final redirect = resolverRedireccionAutenticacion(
        uri: Uri.parse(RutasApp.inicio),
        autenticacionCargando: false,
        autenticado: true,
        enRecuperacion: true,
      );

      expect(redirect, RutasApp.restablecerPassword);
    });
  });
}
