import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion de cancelar transaccion aceptada', () {
    final migration = File(
      'supabase/migrations/20260430220000_cancelar_transaccion_aceptada.sql',
    ).readAsStringSync();

    test('crea funcion cancelar_transaccion con security definer', () {
      expect(
        migration,
        contains(
          'create or replace function public.cancelar_transaccion(p_transaccion_id uuid)',
        ),
      );
      expect(migration, contains('security definer'));
      expect(migration, contains('set search_path = public'));
    });

    test('solo permite cancelar a participantes', () {
      expect(
        migration,
        contains(
          'Solo los participantes pueden cancelar esta transaccion',
        ),
      );
    });

    test('solo cancela transacciones aceptadas', () {
      expect(
        migration,
        contains("v_transaccion.estado <> 'aceptada'"),
      );
      expect(
        migration,
        contains(
          'La transaccion no puede cancelarse desde su estado actual',
        ),
      );
    });

    test('cambia estado a cancelada', () {
      expect(
        migration,
        contains("set estado = 'cancelada'"),
      );
    });

    test('devuelve productos a disponible', () {
      expect(
        migration,
        contains("set estado = 'disponible'"),
      );
      expect(
        migration,
        contains("and estado = 'reservado'"),
      );
    });

    test('notifica a la contraparte', () {
      expect(
        migration,
        contains("'transaccion_cancelada'"),
      );
      expect(
        migration,
        contains('v_contraparte_id'),
      );
    });

    test('restringe acceso y concede solo a authenticated', () {
      expect(
        migration,
        contains(
          'revoke all on function public.cancelar_transaccion(uuid) from public, anon, authenticated',
        ),
      );
      expect(
        migration,
        contains(
          'grant execute on function public.cancelar_transaccion(uuid) to authenticated',
        ),
      );
    });

    test('notifica a PostgREST para recargar schema', () {
      expect(migration, contains("notify pgrst, 'reload schema'"));
    });
  });
}
