import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion de renombrado neutral de participantes', () {
    final migration = File(
      'supabase/migrations/20260430184500_renombrar_participantes_transacciones.sql',
    ).readAsStringSync();

    test('renombra columnas de transacciones y conversaciones', () {
      expect(
        migration,
        contains('rename column comprador_id to solicitante_id'),
      );
      expect(
        migration,
        contains('rename column vendedor_id to propietario_id'),
      );
      expect(migration, contains("table_name = 'transacciones'"));
      expect(migration, contains("table_name = 'conversaciones'"));
    });

    test('recrea functions y policies usando nombres neutrales', () {
      expect(migration, contains('t.solicitante_id, t.propietario_id'));
      expect(migration, contains('v_transaccion.solicitante_id'));
      expect(migration, contains('v_transaccion.propietario_id'));
      expect(migration, contains('c.solicitante_id, c.propietario_id'));
      expect(migration, contains('solicitante_id = (select auth.uid())'));
      expect(migration, contains('propietario_id = (select auth.uid())'));
      expect(migration, isNot(contains('excluded.comprador_id')));
      expect(migration, isNot(contains('excluded.vendedor_id')));
    });

    test('renombra indices y constraints principales', () {
      expect(
        migration,
        contains('transacciones_solicitante_estado_creado_en_idx'),
      );
      expect(
        migration,
        contains('transacciones_propietario_estado_creado_en_idx'),
      );
      expect(migration, contains('conversaciones_solicitante_idx'));
      expect(migration, contains('conversaciones_propietario_idx'));
      expect(migration, contains('transacciones_solicitante_id_fkey'));
      expect(migration, contains('transacciones_propietario_id_fkey'));
      expect(migration, contains('conversaciones_solicitante_id_fkey'));
      expect(migration, contains('conversaciones_propietario_id_fkey'));
    });
  });
}
