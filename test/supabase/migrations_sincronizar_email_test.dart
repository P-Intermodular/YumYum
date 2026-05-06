import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion de sincronizacion de email auth-perfiles', () {
    final migration = File(
      'supabase/migrations/20260430200000_sincronizar_email_auth_perfiles.sql',
    ).readAsStringSync();

    test('crea funcion sincronizar_email_perfil con security definer', () {
      expect(
        migration,
        contains(
          'create or replace function public.sincronizar_email_perfil()',
        ),
      );
      expect(migration, contains('security definer'));
      expect(migration, contains('set search_path = public'));
    });

    test('usa IS DISTINCT FROM para comparar emails', () {
      expect(migration, contains('new.email is distinct from old.email'));
    });

    test('actualiza perfiles.email cuando cambia el email', () {
      expect(migration, contains('update public.perfiles'));
      expect(migration, contains('set email = new.email'));
      expect(migration, contains('where id = new.id'));
    });

    test('crea trigger after update on auth.users', () {
      expect(migration, contains('after update on auth.users'));
      expect(
        migration,
        contains('execute function public.sincronizar_email_perfil()'),
      );
    });

    test('trigger es idempotente con drop if exists previo', () {
      expect(
        migration,
        contains(
          'drop trigger if exists trigger_sincronizar_email_perfil on auth.users',
        ),
      );
    });

    test('revoca acceso directo a la funcion para roles de app', () {
      expect(
        migration,
        contains(
          'revoke all on function public.sincronizar_email_perfil() from public, anon, authenticated',
        ),
      );
    });
  });
}
