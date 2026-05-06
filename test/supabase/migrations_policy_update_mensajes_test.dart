import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion de policy de update sobre mensajes', () {
    final migration = File(
      'supabase/migrations/20260501002200_policy_update_mensajes.sql',
    ).readAsStringSync();

    test('crea la policy de update para participantes', () {
      expect(
        migration,
        contains(
          'drop policy if exists "Participantes pueden actualizar mensajes ajenos" '
          'on public.mensajes;',
        ),
      );
      expect(
        migration,
        contains(
          'create policy "Participantes pueden actualizar mensajes ajenos"',
        ),
      );
      expect(migration, contains('on public.mensajes for update'));
    });

    test('excluye al propio remitente y exige pertenecer a la conversacion', () {
      expect(migration, contains('remitente_id <> (select auth.uid())'));
      expect(
        migration,
        contains(
          '(select auth.uid()) in (c.solicitante_id, c.propietario_id)',
        ),
      );
    });

    test(
      'otorga GRANT UPDATE solo sobre la columna leido_en para que la RLS '
      'tenga efecto real (sin esto, el cliente recibe permission denied)',
      () {
        expect(
          migration,
          contains('grant update (leido_en) on public.mensajes to authenticated'),
        );
      },
    );

    test('notifica a PostgREST para recargar schema', () {
      expect(migration, contains("notify pgrst, 'reload schema'"));
    });
  });
}
