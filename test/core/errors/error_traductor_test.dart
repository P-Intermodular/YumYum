import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumyum/core/errors/app_exception.dart';
import 'package:yumyum/core/errors/error_traductor.dart';

void main() {
  group('ErrorTraductor', () {
    group('PostgrestException', () {
      test('traduce error de RPC directamente', () {
        const error = PostgrestException(
          message: 'Ya tienes una solicitud pendiente para este producto',
        );
        expect(
          ErrorTraductor.traducir(error),
          'Ya tienes una solicitud pendiente para este producto',
        );
      });

      test('traduce duplicate key a mensaje legible', () {
        const error = PostgrestException(
          message: 'duplicate key violates unique constraint',
          code: '23505',
        );
        expect(
          ErrorTraductor.traducir(error),
          'Esta operación ya fue realizada.',
        );
      });

      test('traduce permission denied', () {
        const error = PostgrestException(
          message: 'permission denied for table productos',
          code: '42501',
        );
        expect(
          ErrorTraductor.traducir(error),
          'No tienes permisos para realizar esta acción.',
        );
      });

      test('devuelve fallback para errores desconocidos', () {
        const error = PostgrestException(
          message: 'some internal error xyz',
        );
        expect(
          ErrorTraductor.traducir(error),
          'Error al procesar la solicitud. Inténtalo de nuevo.',
        );
      });
    });

    group('AuthException', () {
      test('traduce credenciales invalidas', () {
        const error = AuthException('Invalid login credentials');
        expect(
          ErrorTraductor.traducir(error),
          'Correo o contraseña incorrectos.',
        );
      });

      test('traduce usuario ya registrado', () {
        const error = AuthException('User already registered');
        expect(
          ErrorTraductor.traducir(error),
          'Ya existe una cuenta con este correo.',
        );
      });

      test('traduce rate limit', () {
        const error = AuthException('Email rate limit exceeded');
        expect(
          ErrorTraductor.traducir(error),
          'Demasiados intentos. Espera un momento e inténtalo de nuevo.',
        );
      });

      test('traduce sesion caducada', () {
        const error = AuthException('Session expired');
        expect(
          ErrorTraductor.traducir(error),
          'Tu sesión ha caducado. Vuelve a iniciar sesión.',
        );
      });
    });

    group('StorageException', () {
      test('traduce payload too large', () {
        const error = StorageException('Payload too large');
        expect(
          ErrorTraductor.traducir(error),
          'La imagen es demasiado grande. Intenta con una más pequeña.',
        );
      });

      test('traduce permission denied', () {
        const error = StorageException('Not allowed');
        expect(
          ErrorTraductor.traducir(error),
          'No tienes permiso para subir este archivo.',
        );
      });
    });

    test('devuelve null para errores no reconocidos', () {
      expect(ErrorTraductor.traducir(Exception('algo')), isNull);
      expect(ErrorTraductor.traducir(StateError('bad state')), isNull);
    });
  });

  group('mensajeError integracion', () {
    test('AppException tiene prioridad', () {
      expect(mensajeError(const AppException('Error de dominio')),
          'Error de dominio');
    });

    test('PostgrestException se traduce automaticamente', () {
      const error = PostgrestException(
        message: 'El producto no esta disponible',
      );
      expect(mensajeError(error), 'El producto no esta disponible');
    });

    test('AuthException se traduce automaticamente', () {
      const error = AuthException('Invalid login credentials');
      expect(mensajeError(error), 'Correo o contraseña incorrectos.');
    });

    test('error generico pasa como fallback', () {
      expect(mensajeError(Exception('algo raro')), 'algo raro');
    });

    test('null devuelve mensaje generico', () {
      expect(mensajeError(null), 'Ha ocurrido un error inesperado');
    });
  });
}
