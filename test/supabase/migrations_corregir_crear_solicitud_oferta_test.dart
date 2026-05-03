import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion de correccion de crear_solicitud_oferta', () {
    final migration = File(
      'supabase/migrations/20260501010000_corregir_crear_solicitud_oferta.sql',
    ).readAsStringSync();

    // Cuerpo SQL sin lineas de comentario, para que las verificaciones de
    // ausencia no se vean afectadas por la cabecera explicativa.
    final sqlSinComentarios = migration
        .split('\n')
        .where((linea) => !linea.trimLeft().startsWith('--'))
        .join('\n');

    test('redefine la RPC con nombres de columna actuales', () {
      expect(
        migration,
        contains('create or replace function public.crear_solicitud_oferta('),
      );
      expect(
        migration,
        contains(
          'insert into public.conversaciones (\n'
          '    solicitud_id,\n'
          '    producto_id,\n'
          '    solicitante_id,\n'
          '    propietario_id\n'
          '  )',
        ),
      );
    });

    test('no reintroduce las columnas renombradas en el cuerpo SQL', () {
      expect(sqlSinComentarios, isNot(contains('comprador_id')));
      expect(sqlSinComentarios, isNot(contains('vendedor_id')));
    });

    test('mantiene la guarda de duplicados pendientes', () {
      expect(
        migration,
        contains('Ya tienes una solicitud pendiente para este producto'),
      );
    });

    test('preserva el resto de validaciones originales', () {
      expect(migration, contains('Autenticacion requerida'));
      expect(migration, contains('El producto no esta disponible'));
      expect(
        migration,
        contains('El tipo de solicitud no coincide con la oferta'),
      );
      expect(migration, contains('No puedes solicitar tu propio producto'));
      expect(
        migration,
        contains(
          'Las solicitudes de venta no pueden incluir producto ofrecido',
        ),
      );
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
