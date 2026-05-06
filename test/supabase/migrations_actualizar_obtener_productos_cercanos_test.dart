import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion de actualizacion de obtener_productos_cercanos', () {
    final migration = File(
      'supabase/migrations/20260506172108_actualizar_obtener_productos_cercanos_campos_nuevos.sql',
    ).readAsStringSync();

    final sqlSinComentarios = migration
        .split('\n')
        .where((linea) => !linea.trimLeft().startsWith('--'))
        .join('\n');

    test('hace DROP previo de la firma anterior antes de recrear', () {
      // Indispensable: cambia el RETURNS TABLE y CREATE OR REPLACE no
      // admite cambios en el tipo de retorno.
      expect(
        migration,
        contains(
          'drop function if exists public.obtener_productos_cercanos(\n'
          '  double precision,\n'
          '  double precision,\n'
          '  double precision,\n'
          '  integer\n'
          ');',
        ),
      );
      // Y el CREATE no es OR REPLACE (porque ya hicimos DROP).
      expect(
        migration,
        contains('create function public.obtener_productos_cercanos('),
      );
      expect(
        sqlSinComentarios,
        isNot(contains('create or replace function public.obtener_productos_cercanos(')),
      );
    });

    test('expone los campos nuevos en RETURNS TABLE', () {
      // Estos son los que faltaban y rompían filtros del feed/mapa.
      expect(migration, contains('categoria text,'));
      expect(migration, contains('etiquetas text[],'));
      expect(migration, contains('alergenos text[],'));
      expect(migration, contains('sin_alergenos_declarados boolean,'));
      expect(migration, contains('raciones_totales integer,'));
      expect(migration, contains('raciones_disponibles integer,'));
    });

    test('selecciona los nuevos campos desde la tabla productos', () {
      expect(migration, contains('pr.categoria,'));
      expect(migration, contains('pr.etiquetas,'));
      expect(migration, contains('pr.alergenos,'));
      expect(migration, contains('pr.sin_alergenos_declarados,'));
      expect(migration, contains('pr.raciones_totales,'));
      expect(migration, contains('pr.raciones_disponibles,'));
    });

    test('preserva los filtros geográficos y de estado originales', () {
      expect(migration, contains("where pr.estado = 'disponible'"));
      expect(migration, contains('earth_box('));
      expect(migration, contains('earth_distance('));
      expect(migration, contains('order by distancia_km asc, pr.creado_en desc'));
      expect(
        migration,
        contains('limit greatest(coalesce(p_limite, 50), 1);'),
      );
    });

    test('mantiene la forma del JSON de perfiles e imágenes', () {
      // Sin estos joins el feed se queda sin avatar de cocinero ni portada.
      expect(migration, contains('jsonb_build_object('));
      expect(migration, contains("'url_avatar', p.url_avatar"));
      expect(migration, contains("'valoracion_media', p.valoracion_media"));
      expect(migration, contains('from public.imagenes_producto ip'));
      expect(migration, contains("'url_publica', ip.url_publica"));
    });

    test('reaplica las ACLs tras el DROP', () {
      // El DROP elimina los grants; sin esto la app dejaría de poder llamar
      // la RPC.
      expect(
        migration,
        contains(
          'revoke all on function public.obtener_productos_cercanos(\n'
          '  double precision,\n'
          '  double precision,\n'
          '  double precision,\n'
          '  integer\n'
          ') from public, anon, authenticated;',
        ),
      );
      expect(
        migration,
        contains(
          'grant execute on function public.obtener_productos_cercanos(\n'
          '  double precision,\n'
          '  double precision,\n'
          '  double precision,\n'
          '  integer\n'
          ') to authenticated;',
        ),
      );
    });

    test('marca security invoker (no escala privilegios)', () {
      // La RPC solo lee productos públicos disponibles; no necesita definer.
      expect(migration, contains('security invoker'));
      expect(sqlSinComentarios, isNot(contains('security definer')));
    });

    test('notifica a PostgREST para recargar schema', () {
      expect(migration, contains("notify pgrst, 'reload schema'"));
    });
  });
}
