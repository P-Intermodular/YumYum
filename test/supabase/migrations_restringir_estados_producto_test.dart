import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion de restringir estados de producto', () {
    final migration = File(
      'supabase/migrations/20260430222000_restringir_estados_producto.sql',
    ).readAsStringSync();

    test('crea funcion de validacion de transicion de estado', () {
      expect(
        migration,
        contains(
          'create or replace function public.validar_transicion_estado_producto()',
        ),
      );
      expect(migration, contains('returns trigger'));
    });

    test('distingue cliente de RPCs internas por current_user', () {
      expect(
        migration,
        contains("current_user <> 'authenticated'"),
      );
    });

    test('permite editar campos sin cambiar estado', () {
      expect(
        migration,
        contains('old.estado is not distinct from new.estado'),
      );
    });

    test('permite transicion disponible a cancelado desde cliente', () {
      expect(
        migration,
        contains("old.estado = 'disponible' and new.estado = 'cancelado'"),
      );
    });

    test('lanza error para transiciones no permitidas', () {
      expect(
        migration,
        contains('No tienes permiso para cambiar el estado del producto'),
      );
    });

    test('crea trigger BEFORE UPDATE en productos', () {
      expect(
        migration,
        contains('trg_validar_transicion_estado_producto'),
      );
      expect(
        migration,
        contains('before update on public.productos'),
      );
    });

    test('revoca acceso directo a la funcion', () {
      expect(
        migration,
        contains(
          'revoke all on function public.validar_transicion_estado_producto() from public, anon, authenticated',
        ),
      );
    });

    test('notifica a PostgREST para recargar schema', () {
      expect(migration, contains("notify pgrst, 'reload schema'"));
    });
  });
}
