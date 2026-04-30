import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion de bloquear solicitudes duplicadas', () {
    final migration = File(
      'supabase/migrations/20260430221000_bloquear_solicitudes_duplicadas.sql',
    ).readAsStringSync();

    test('resuelve duplicados existentes antes del indice', () {
      expect(migration, contains('partition by producto_id, solicitante_id'));
      expect(migration, contains('order by creado_en desc'));
      expect(migration, contains("set estado = 'cancelada'"));
      expect(migration, contains('where rn > 1'));
    });

    test('crea indice unico parcial sobre pendientes', () {
      expect(
        migration,
        contains('solicitudes_oferta_pendiente_unica_idx'),
      );
      expect(
        migration,
        contains('(producto_id, solicitante_id)'),
      );
      expect(
        migration,
        contains("where estado = 'pendiente'"),
      );
    });

    test('redefine crear_solicitud_oferta con guarda de duplicados', () {
      expect(
        migration,
        contains(
          'create or replace function public.crear_solicitud_oferta(',
        ),
      );
      expect(
        migration,
        contains(
          'Ya tienes una solicitud pendiente para este producto',
        ),
      );
    });

    test('mantiene la logica original de la RPC intacta', () {
      // Validaciones que ya existian.
      expect(migration, contains('Autenticacion requerida'));
      expect(migration, contains('El producto no esta disponible'));
      expect(migration, contains('No puedes solicitar tu propio producto'));
      expect(
        migration,
        contains(
          'Las solicitudes de intercambio requieren producto ofrecido',
        ),
      );
      expect(migration, contains('solicitud_oferta_creada'));
    });

    test('notifica a PostgREST para recargar schema', () {
      expect(migration, contains("notify pgrst, 'reload schema'"));
    });
  });
}
