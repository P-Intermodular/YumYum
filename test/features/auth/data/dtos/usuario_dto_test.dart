import 'package:flutter_test/flutter_test.dart';
import 'package:yumyum/features/auth/data/dtos/usuario_dto.dart';

void main() {
  group('UsuarioDto', () {
    test('mapea perfiles publicos aunque no incluyan datos privados', () {
      final usuario = UsuarioDto.desdePerfil({
        'id': 'usuario-1',
        'nombre': 'Ana',
        'url_avatar': 'avatar.png',
        'valoracion_media': 4.5,
        'numero_valoraciones': 3,
      });

      expect(usuario.id, 'usuario-1');
      expect(usuario.nombre, 'Ana');
      expect(usuario.correo, isEmpty);
      expect(usuario.urlImagenPerfil, 'avatar.png');
      expect(usuario.valoracionMedia, 4.5);
      expect(usuario.numeroValoraciones, 3);
      expect(usuario.certificacionSanitaria, isNull);
      expect(usuario.latitudPredeterminada, isNull);
      expect(usuario.longitudPredeterminada, isNull);
    });
  });
}
