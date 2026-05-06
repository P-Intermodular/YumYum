import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migracion de cancelar solicitud pendiente', () {
    final migration = File(
      'supabase/migrations/20260430215000_cancelar_solicitud_pendiente.sql',
    ).readAsStringSync();

    test('crea funcion cancelar_solicitud_oferta con security definer', () {
      expect(
        migration,
        contains(
          'create or replace function public.cancelar_solicitud_oferta(p_solicitud_id uuid)',
        ),
      );
      expect(migration, contains('security definer'));
      expect(migration, contains('set search_path = public'));
    });

    test('solo permite cancelar al solicitante', () {
      expect(
        migration,
        contains('v_solicitud.solicitante_id <> v_usuario_id'),
      );
      expect(
        migration,
        contains('Solo el solicitante puede cancelar esta solicitud'),
      );
    });

    test('solo cancela solicitudes pendientes', () {
      expect(
        migration,
        contains("v_solicitud.estado <> 'pendiente'"),
      );
      expect(
        migration,
        contains('La solicitud no esta pendiente'),
      );
    });

    test('cambia estado a cancelada y rellena respondido_en', () {
      expect(
        migration,
        contains("set estado = 'cancelada'"),
      );
      expect(migration, contains('respondido_en = now()'));
    });

    test('notifica al propietario del producto', () {
      expect(
        migration,
        contains('v_solicitud.propietario_id'),
      );
      expect(
        migration,
        contains("'solicitud_oferta_cancelada'"),
      );
    });

    test('restringe acceso y concede solo a authenticated', () {
      expect(
        migration,
        contains(
          'revoke all on function public.cancelar_solicitud_oferta(uuid) from public, anon, authenticated',
        ),
      );
      expect(
        migration,
        contains(
          'grant execute on function public.cancelar_solicitud_oferta(uuid) to authenticated',
        ),
      );
    });
  });
}
