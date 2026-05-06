import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion preferencias de notificaciones', () {
    final migration = File(
      'supabase/migrations/20260506213607_anadir_preferencias_notificaciones.sql',
    ).readAsStringSync();

    test('añade columna jsonb con default sensato', () {
      // jsonb permite añadir nuevas categorías sin migración futura.
      // Default con las tres iniciales en true para no silenciar de golpe a
      // los usuarios existentes tras desplegar.
      expect(
        migration,
        contains(
          "alter table public.perfiles\n"
          "  add column preferencias_notificaciones jsonb not null\n"
          "  default '{\"pedidos\":true,\"mensajes\":true,\"valoraciones\":true}'::jsonb;",
        ),
      );
    });

    test('concede grants column-level de select y update', () {
      expect(
        migration,
        contains('grant select (preferencias_notificaciones) on public.perfiles to authenticated;'),
      );
      expect(
        migration,
        contains('grant update (preferencias_notificaciones) on public.perfiles to authenticated;'),
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

    test('expone preferencias_notificaciones en el shape y selecciona el campo', () {
      expect(migration, contains('preferencias_notificaciones jsonb,'));
      expect(migration, contains('p.preferencias_notificaciones,'));
    });

    test('preserva alergenos y pedidos_completados (no perder cosas previas)', () {
      // Riesgo recurrente al recrear la RPC: olvidar mantener campos
      // añadidos en migraciones anteriores.
      expect(migration, contains('alergenos text[],'));
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
