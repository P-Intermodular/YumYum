import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion de RPC eliminar_producto', () {
    final migration = File(
      'supabase/migrations/20260506174051_eliminar_producto_rpc.sql',
    ).readAsStringSync();

    final sqlSinComentarios = migration
        .split('\n')
        .where((linea) => !linea.trimLeft().startsWith('--'))
        .join('\n');

    test('crea la funcion con la firma correcta', () {
      expect(
        migration,
        contains('create or replace function public.eliminar_producto(p_producto_id uuid)'),
      );
      // Devuelve boolean: true=delete real, false=soft delete. El cliente lo
      // usa para decidir si limpia Storage.
      expect(migration, contains('returns boolean'));
      expect(migration, contains('language plpgsql'));
      expect(migration, contains('set search_path = public'));
    });

    test('usa security definer para saltar el trigger de transicion', () {
      // El trigger validar_transicion_estado_producto solo permite
      // disponible→cancelado desde rol authenticated. Definer evita que
      // bloquee transiciones desde 'agotado'/'reservado'.
      expect(migration, contains('security definer'));
    });

    test('exige autenticacion y propiedad antes de cualquier cambio', () {
      expect(migration, contains("raise exception 'Autenticacion requerida'"));
      expect(migration, contains("raise exception 'Producto no encontrado'"));
      expect(
        migration,
        contains("raise exception 'Solo el propietario puede eliminar este plato'"),
      );
      // Bloqueo pesimista del producto durante la operacion.
      expect(migration, contains('for update'));
    });

    test('cuenta actividad en las cuatro tablas con FK RESTRICT', () {
      // Si alguna referencia el producto, un DELETE real fallaría: por eso
      // contamos antes de decidir entre delete y soft delete.
      expect(migration, contains('from public.solicitudes_oferta'));
      expect(migration, contains('producto_ofrecido_id = p_producto_id'));
      expect(migration, contains('from public.transacciones'));
      expect(migration, contains('from public.valoraciones'));
      expect(migration, contains('producto_valorado_id = p_producto_id'));
      expect(migration, contains('from public.conversaciones'));
    });

    test('hace DELETE real cuando no hay actividad y devuelve true', () {
      expect(
        migration,
        contains('delete from public.productos where id = p_producto_id'),
      );
      expect(sqlSinComentarios, contains('return true'));
    });

    test('hace soft delete idempotente con actividad y devuelve false', () {
      expect(
        migration,
        contains(
          "update public.productos\n"
          "    set estado = 'cancelado'\n"
          "    where id = p_producto_id and estado <> 'cancelado'",
        ),
      );
      expect(sqlSinComentarios, contains('return false'));
    });

    test('aplica grants restrictivos', () {
      expect(
        migration,
        contains(
          'revoke all on function public.eliminar_producto(uuid)\n'
          '  from public, anon, authenticated;',
        ),
      );
      expect(
        migration,
        contains(
          'grant execute on function public.eliminar_producto(uuid) to authenticated;',
        ),
      );
    });

    test('notifica a PostgREST para recargar schema', () {
      expect(migration, contains("notify pgrst, 'reload schema'"));
    });
  });
}
