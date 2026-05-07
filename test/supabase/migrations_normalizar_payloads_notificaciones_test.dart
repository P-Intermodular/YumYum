import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion normalizar payloads de notificaciones', () {
    final migration = File(
      'supabase/migrations/20260507121504_normalizar_payloads_notificaciones.sql',
    ).readAsStringSync();

    test('solicitud_oferta_creada incluye conversacion_id en el payload', () {
      // Antes solo llevaba solicitud_id + producto_id; añadimos conversacion_id
      // para simetría con el resto y para futuras vistas que quieran saltar al
      // chat directamente.
      expect(
        migration,
        contains(
          "jsonb_build_object(\n"
          "      'solicitud_id', v_solicitud_id,\n"
          "      'producto_id', p_producto_id,\n"
          "      'conversacion_id', v_conversacion_id\n"
          "    )",
        ),
      );
    });

    test('solicitud_oferta_aceptada incluye producto_id', () {
      // Era la única notificación de solicitud sin producto_id. Lo añadimos
      // para fallback al producto si en algún momento se quisiera.
      expect(
        migration,
        contains(
          "jsonb_build_object(\n"
          "      'solicitud_id', v_solicitud.id,\n"
          "      'producto_id', v_solicitud.producto_id,\n"
          "      'transaccion_id', v_transaccion_id,\n"
          "      'conversacion_id', v_conversacion_id\n"
          "    )",
        ),
      );
    });

    test('solicitud_oferta_auto_denegada expone conversacion_id desde el CTE', () {
      // El CTE `denegadas` no tiene la conversacion; LEFT JOIN con
      // conversaciones por solicitud_id la trae sin romper la cadena.
      expect(
        migration,
        contains(
          "from denegadas d\n"
          "  left join public.conversaciones c on c.solicitud_id = d.id;",
        ),
      );
      expect(
        migration,
        contains("'conversacion_id', c.id"),
      );
    });

    test('solicitud_oferta_denegada carga conversacion_id antes del insert', () {
      expect(
        migration,
        contains(
          "select id into v_conversacion_id\n"
          "  from public.conversaciones\n"
          "  where solicitud_id = v_solicitud.id;\n\n"
          "  insert into public.notificaciones (usuario_id, tipo, titulo, contenido, datos)\n"
          "  values (\n"
          "    v_solicitud.solicitante_id,\n"
          "    'solicitud_oferta_denegada',",
        ),
      );
    });

    test('solicitud_oferta_cancelada carga conversacion_id antes del insert', () {
      expect(
        migration,
        contains(
          "    'solicitud_oferta_cancelada',\n"
          "    'Solicitud cancelada',\n"
          "    'Una solicitud para tu producto ha sido cancelada por el solicitante.',\n"
          "    jsonb_build_object(\n"
          "      'solicitud_id', v_solicitud.id,\n"
          "      'producto_id', v_solicitud.producto_id,\n"
          "      'conversacion_id', v_conversacion_id\n"
          "    )",
        ),
      );
    });

    test('transaccion_cancelada lleva solicitud_id y conversacion_id', () {
      // Riesgo recurrente: olvidar solicitud_id porque el RPC opera sobre
      // v_transaccion. Lo testamos explícitamente.
      expect(
        migration,
        contains(
          "jsonb_build_object(\n"
          "      'transaccion_id', v_transaccion.id,\n"
          "      'solicitud_id', v_transaccion.solicitud_id,\n"
          "      'producto_id', v_transaccion.producto_id,\n"
          "      'conversacion_id', v_conversacion_id\n"
          "    )",
        ),
      );
    });

    test('corrige tildes en los textos visibles al usuario', () {
      // Las RPCs nuevas se introdujeron sin tildes en algunos literales.
      expect(migration, contains("'Transacción cancelada'"));
      expect(
        migration,
        contains("'Una transacción ha sido cancelada por la otra parte.'"),
      );
      expect(
        migration,
        contains(
          "'Una solicitud relacionada ya no está disponible porque otra fue aceptada.'",
        ),
      );
    });

    test('mantiene firmas de las cinco RPCs sin alterarlas', () {
      // Si cambia la firma necesitaríamos drop + recreate + grants. Aquí solo
      // tocamos el cuerpo, así que las firmas deben aparecer idénticas.
      expect(
        migration,
        contains(
          'create or replace function public.crear_solicitud_oferta(\n'
          '  p_producto_id uuid,\n'
          '  p_tipo_solicitud text,\n'
          '  p_producto_ofrecido_id uuid default null,\n'
          '  p_mensaje text default null,\n'
          '  p_cantidad int default 1,\n'
          '  p_cantidad_ofrecida int default null\n'
          ')',
        ),
      );
      expect(
        migration,
        contains(
          'create or replace function public.aceptar_solicitud_oferta(p_solicitud_id uuid)',
        ),
      );
      expect(
        migration,
        contains(
          'create or replace function public.denegar_solicitud_oferta(p_solicitud_id uuid)',
        ),
      );
      expect(
        migration,
        contains(
          'create or replace function public.cancelar_solicitud_oferta(p_solicitud_id uuid)',
        ),
      );
      expect(
        migration,
        contains(
          'create or replace function public.cancelar_transaccion(p_transaccion_id uuid)',
        ),
      );
    });

    test('notifica a PostgREST para recargar schema', () {
      expect(migration, contains("notify pgrst, 'reload schema'"));
    });
  });
}
