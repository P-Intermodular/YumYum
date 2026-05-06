import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumyum/core/supabase/supabase_client_provider.dart';
import 'package:yumyum/features/auth/controllers/auth_controller.dart';
import 'package:yumyum/features/auth/controllers/restablecer_password_controller.dart';
import 'package:yumyum/features/auth/domain/entities/usuario_model.dart';
import 'package:yumyum/features/auth/domain/repositories/auth_repository.dart';
import 'package:yumyum/features/auth/providers/auth_repository_provider.dart';

import '../../../helpers/auth_test_utils.dart';

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

  group('RestablecerPasswordController', () {
    test('transiciona de formulario a guardando y password actualizada',
        () async {
      final repository = _AuthRepositoryFake();
      repository.restablecerPasswordCompleter = Completer<void>();

      final container = ProviderContainer(
        overrides: [
          autenticacionRepositoryProvider.overrideWithValue(repository),
          supabaseClientProvider.overrideWithValue(supabaseTestClient()),
        ],
      );
      addTearDown(container.dispose);
      container.read(autenticacionProvider);
      await container.pump();
      container
          .read(autenticacionProvider.notifier)
          .activarRecuperacionPassword();

      const parametros = ParametrosRestablecerPassword(
        tokenHash: null,
        tipo: null,
        codigo: null,
      );
      final provider = restablecerPasswordControllerProvider(parametros);

      expect(container.read(provider).paso,
          PasoRestablecerPassword.formularioListo);

      final guardado = container
          .read(provider.notifier)
          .guardarNuevaPassword('nueva-password-segura');

      expect(container.read(provider).paso,
          PasoRestablecerPassword.guardandoPassword);
      expect(repository.ultimaPasswordRestablecida, 'nueva-password-segura');

      repository.restablecerPasswordCompleter!.complete();
      await guardado;

      expect(
        container.read(provider).paso,
        PasoRestablecerPassword.passwordActualizada,
      );
      expect(container.read(autenticacionProvider).enRecuperacion, isFalse);
      expect(repository.cerrarSesionCalls, 1);
    });
  });
}

class _AuthRepositoryFake implements AuthRepository {
  Completer<void>? restablecerPasswordCompleter;
  String? ultimaPasswordRestablecida;
  int cerrarSesionCalls = 0;

  @override
  Future<UsuarioModel> iniciarSesion(String correo, String password) {
    throw UnimplementedError();
  }

  @override
  Future<UsuarioModel> registrarUsuario(
    String nombre,
    String correo,
    String password,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> cerrarSesion() async {
    cerrarSesionCalls++;
  }

  @override
  Future<UsuarioModel?> obtenerUsuarioActual() async => null;

  @override
  Future<UsuarioModel> actualizarPerfil(UsuarioModel usuario) {
    throw UnimplementedError();
  }

  @override
  Future<String> subirAvatar(String usuarioId, dynamic imagen) {
    throw UnimplementedError();
  }

  @override
  Future<UsuarioModel> actualizarUbicacionPredeterminada(UsuarioModel usuario) {
    throw UnimplementedError();
  }

  @override
  Future<void> enviarEmailRecuperacion(String correo) {
    throw UnimplementedError();
  }

  @override
  Future<void> verificarRecuperacionPassword(String tokenHash) {
    throw UnimplementedError();
  }

  @override
  Future<void> verificarCodigoRecuperacionPassword(String codigo) {
    throw UnimplementedError();
  }

  @override
  Future<void> restablecerPassword(String nuevaPassword) {
    ultimaPasswordRestablecida = nuevaPassword;
    return restablecerPasswordCompleter?.future ?? Future.value();
  }

  @override
  Future<UsuarioModel> actualizarPreferenciasNotificaciones(
    String usuarioId,
    Map<String, bool> preferencias,
  ) {
    throw UnimplementedError();
  }
}
