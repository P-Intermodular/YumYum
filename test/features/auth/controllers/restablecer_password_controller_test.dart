import 'package:flutter_test/flutter_test.dart';
import 'package:yumyum/features/auth/controllers/restablecer_password_controller.dart';

void main() {
  group('crearEstadoInicialRestablecerPassword', () {
    test('marca enlace invalido cuando no hay parametros validables', () {
      const parametros = ParametrosRestablecerPassword(
        tokenHash: null,
        tipo: null,
        codigo: null,
      );

      final estado = crearEstadoInicialRestablecerPassword(parametros, false);

      expect(estado.paso, PasoRestablecerPassword.enlaceInvalido);
    });

    test('espera confirmacion con token_hash recovery', () {
      const parametros = ParametrosRestablecerPassword(
        tokenHash: 'token',
        tipo: 'recovery',
        codigo: null,
      );

      final estado = crearEstadoInicialRestablecerPassword(parametros, false);

      expect(estado.paso, PasoRestablecerPassword.esperandoConfirmacion);
    });

    test('espera confirmacion con codigo PKCE', () {
      const parametros = ParametrosRestablecerPassword(
        tokenHash: null,
        tipo: null,
        codigo: 'code',
      );

      final estado = crearEstadoInicialRestablecerPassword(parametros, false);

      expect(estado.paso, PasoRestablecerPassword.esperandoConfirmacion);
    });

    test('muestra formulario si recovery ya esta activo', () {
      const parametros = ParametrosRestablecerPassword(
        tokenHash: null,
        tipo: null,
        codigo: null,
      );

      final estado = crearEstadoInicialRestablecerPassword(parametros, true);

      expect(estado.paso, PasoRestablecerPassword.formularioListo);
    });
  });
}
