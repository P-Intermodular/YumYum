import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion de privacidad de perfiles', () {
    final migration = File(
      'supabase/migrations/20260430130000_hardening_privacidad_perfiles.sql',
    ).readAsStringSync();

    test('acota el perfil devuelto por obtener_productos_cercanos', () {
      expect(migration, contains('jsonb_build_object'));
      expect(migration, isNot(contains('select to_jsonb(p)')));
      expect(
        migration,
        contains("'numero_valoraciones', p.numero_valoraciones"),
      );
    });

    test('no expone ruta_storage en imagenes de productos cercanos', () {
      expect(migration, isNot(contains('to_jsonb(ip)')));
      expect(migration, contains("'url_publica', ip.url_publica"));
      expect(migration, contains('revoke select on public.imagenes_producto'));
      expect(migration,
          contains(') on public.imagenes_producto to authenticated'));
    });

    test('restringe perfiles publicos y conserva RPC de perfil propio', () {
      expect(migration, contains('revoke select on public.perfiles'));
      expect(migration, contains('grant select ('));
      expect(
        migration,
        contains('create or replace function public.obtener_mi_perfil()'),
      );
      expect(
        migration,
        contains('grant execute on function public.obtener_mi_perfil()'),
      );
    });

    test('quita actualizado_en de grants de escritura directa', () {
      expect(
        migration,
        contains('revoke update (actualizado_en) on public.productos'),
      );

      // El grant update de perfiles no debe incluir actualizado_en.
      // Extraemos el bloque entre 'grant update (' y ') on public.perfiles'
      // y comprobamos que actualizado_en no aparece ahí.
      final grantUpdatePerfiles = RegExp(
        r'grant update \((.*?)\) on public\.perfiles to authenticated',
        dotAll: true,
      ).firstMatch(migration);
      expect(grantUpdatePerfiles, isNotNull,
          reason: 'debe existir un grant update en perfiles');
      expect(grantUpdatePerfiles!.group(1), isNot(contains('actualizado_en')),
          reason: 'actualizado_en no debe estar en grant update de perfiles');
    });

    test('grant select de perfiles excluye todos los campos privados', () {
      final grantSelectPerfiles = RegExp(
        r'grant select \((.*?)\) on public\.perfiles to authenticated',
        dotAll: true,
      ).firstMatch(migration);
      expect(grantSelectPerfiles, isNotNull,
          reason: 'debe existir un grant select por columnas en perfiles');
      final columnas = grantSelectPerfiles!.group(1)!;
      for (final privado in [
        'email',
        'ciudad',
        'preferencias',
        'certificacion_sanitaria',
        'latitud_predeterminada',
        'longitud_predeterminada',
        'es_moderador',
      ]) {
        expect(columnas, isNot(contains(privado)),
            reason: '$privado no debe estar en grant select de perfiles');
      }
    });
  });
}
