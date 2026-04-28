import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumyum/features/auth/controllers/auth_controller.dart';
import 'package:yumyum/features/auth/domain/entities/usuario_model.dart';

void main() {
  group('EstadoAutenticacion', () {
    test('arranca cargando y fuera del modo recovery', () {
      const estado = EstadoAutenticacion.inicial();

      expect(estado.isLoading, isTrue);
      expect(estado.hasError, isFalse);
      expect(estado.valueOrNull, isNull);
      expect(estado.enRecuperacion, isFalse);
    });

    test('expone los getters de compatibilidad sobre AsyncData', () {
      final usuario = _usuario();
      final estado = EstadoAutenticacion(
        usuario: AsyncValue.data(usuario),
        enRecuperacion: true,
      );

      expect(estado.isLoading, isFalse);
      expect(estado.hasError, isFalse);
      expect(estado.error, isNull);
      expect(estado.value, same(usuario));
      expect(estado.valueOrNull, same(usuario));
      expect(estado.enRecuperacion, isTrue);
    });

    test('expone carga y error sin perder el flag recovery', () {
      final error = Exception('sesion no disponible');
      final estado = EstadoAutenticacion(
        usuario: AsyncValue<UsuarioModel?>.error(error, StackTrace.current),
        enRecuperacion: true,
      );

      expect(estado.isLoading, isFalse);
      expect(estado.hasError, isTrue);
      expect(estado.error, same(error));
      expect(estado.valueOrNull, isNull);
      expect(estado.enRecuperacion, isTrue);
    });

    test('copyWith conserva valores no modificados', () {
      final usuario = _usuario();
      const cargando = AsyncValue<UsuarioModel?>.loading();
      const estado = EstadoAutenticacion(usuario: cargando);

      final conUsuario = estado.copyWith(usuario: AsyncValue.data(usuario));
      final enRecovery = conUsuario.copyWith(enRecuperacion: true);

      expect(conUsuario.value, same(usuario));
      expect(conUsuario.enRecuperacion, isFalse);
      expect(enRecovery.value, same(usuario));
      expect(enRecovery.enRecuperacion, isTrue);
    });
  });
}

UsuarioModel _usuario() {
  return const UsuarioModel(
    id: 'usuario-1',
    nombre: 'Ana',
    correo: 'ana@example.com',
    urlImagenPerfil: '',
  );
}
