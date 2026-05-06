import 'package:flutter_test/flutter_test.dart';
import 'package:yumyum/features/producto/data/repositories/supabase_producto_repository.dart';

void main() {
  group('SupabaseProductoRepository', () {
    test('productoSelect solo pide campos publicos del propietario', () {
      const select = SupabaseProductoRepository.productoSelect;

      expect(
        select,
        contains('perfiles:perfiles!productos_propietario_id_fkey'),
      );
      expect(select, contains('nombre'));
      expect(select, contains('url_avatar'));
      expect(select, contains('valoracion_media'));
      expect(select, contains('numero_valoraciones'));
      expect(select, isNot(contains('email')));
      expect(select, isNot(contains('certificacion_sanitaria')));
      expect(select, isNot(contains('es_moderador')));
      expect(select, isNot(contains('preferencias')));
      expect(select, isNot(contains('ruta_storage')));
    });
  });
}
