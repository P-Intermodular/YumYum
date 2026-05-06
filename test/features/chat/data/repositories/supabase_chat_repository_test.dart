import 'package:flutter_test/flutter_test.dart';
import 'package:yumyum/features/chat/data/repositories/supabase_chat_repository.dart';

void main() {
  group('SupabaseChatRepository', () {
    test('conversacionSelect solo pide campos publicos de participantes', () {
      const select = SupabaseChatRepository.conversacionSelect;

      expect(select, contains('solicitante:perfiles!'));
      expect(select, contains('propietario:perfiles!'));
      expect(select, contains('nombre'));
      expect(select, contains('url_avatar'));
      expect(select, contains('valoracion_media'));
      expect(select, contains('numero_valoraciones'));
      expect(select, isNot(contains('email')));
      expect(select, isNot(contains('certificacion_sanitaria')));
      expect(select, isNot(contains('es_moderador')));
      expect(select, isNot(contains('preferencias')));
    });
  });
}
