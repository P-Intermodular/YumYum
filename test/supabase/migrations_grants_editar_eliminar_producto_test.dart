import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion de grants para editar/eliminar producto', () {
    final migration = File(
      'supabase/migrations/20260506175507_grants_editar_eliminar_producto.sql',
    ).readAsStringSync();

    test('concede UPDATE column-level para los campos editables nuevos', () {
      // La migracion 20260506005754 dejo UPDATE fuera adrede. Ahora la
      // pantalla de edicion necesita estos seis para no recibir 42501.
      expect(
        migration,
        contains(
          'grant update (\n'
          '  categoria,\n'
          '  etiquetas,\n'
          '  alergenos,\n'
          '  sin_alergenos_declarados,\n'
          '  raciones_totales,\n'
          '  raciones_disponibles\n'
          ') on public.productos to authenticated;',
        ),
      );
    });

    test('expone ruta_storage en SELECT para que el cliente limpie Storage', () {
      expect(
        migration,
        contains(
          'grant select (ruta_storage) on public.imagenes_producto to authenticated;',
        ),
      );
    });

    test('habilita DELETE en imagenes_producto a nivel tabla', () {
      // DELETE no admite granularidad por columna; va a nivel tabla.
      expect(
        migration,
        contains('grant delete on public.imagenes_producto to authenticated;'),
      );
    });

    test('crea policy DELETE acotada al propietario del producto', () {
      expect(
        migration,
        contains(
          'create policy "Usuarios pueden borrar imagenes de sus productos"\n'
          '  on public.imagenes_producto for delete',
        ),
      );
      // La policy no debe permitir borrar imágenes de productos ajenos.
      expect(migration, contains('propietario_id = (select auth.uid())'));
    });

    test('notifica a PostgREST para recargar schema', () {
      expect(migration, contains("notify pgrst, 'reload schema'"));
    });
  });
}
