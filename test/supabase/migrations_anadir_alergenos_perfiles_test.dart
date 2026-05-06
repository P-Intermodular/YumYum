import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion alergenos en perfiles', () {
    final migration = File(
      'supabase/migrations/20260506195439_anadir_alergenos_perfiles.sql',
    ).readAsStringSync();

    test('añade columna alergenos con default vacío', () {
      // text[] not null default '{}' garantiza que perfiles existentes
      // empiezan con la lista vacía sin fallar el NOT NULL.
      expect(
        migration,
        contains(
          "alter table public.perfiles\n"
          "  add column alergenos text[] not null default '{}';",
        ),
      );
    });

    test('concede grants column-level de select y update', () {
      // PostgREST exige column-level grants aunque la policy lo permita.
      expect(
        migration,
        contains('grant select (alergenos) on public.perfiles to authenticated;'),
      );
      expect(
        migration,
        contains('grant update (alergenos) on public.perfiles to authenticated;'),
      );
    });

    test('recrea obtener_mi_perfil con DROP previo', () {
      // CREATE OR REPLACE no admite cambios en RETURNS TABLE.
      expect(
        migration,
        contains('drop function if exists public.obtener_mi_perfil();'),
      );
      expect(
        migration,
        contains('create function public.obtener_mi_perfil()'),
      );
    });

    test('expone alergenos en el shape de salida y selecciona el campo', () {
      expect(migration, contains('alergenos text[],'));
      expect(migration, contains('p.alergenos,'));
    });

    test('preserva pedidos_completados como conteo desde transacciones', () {
      // Métrica añadida en la migración 20260505212854. Si la nueva RPC la
      // pierde, el perfil propio se quedaría sin esa columna.
      expect(migration, contains('pedidos_completados integer,'));
      expect(
        migration,
        contains("from public.transacciones t\n        where t.propietario_id = p.id\n          and t.estado = 'completada'"),
      );
    });

    test('aplica grants a authenticated con default deny', () {
      expect(
        migration,
        contains('revoke all on function public.obtener_mi_perfil() from public, anon, authenticated;'),
      );
      expect(
        migration,
        contains('grant execute on function public.obtener_mi_perfil() to authenticated;'),
      );
    });

    test('notifica a PostgREST para recargar schema', () {
      expect(migration, contains("notify pgrst, 'reload schema'"));
    });
  });
}
