import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../data/repositories/supabase_chat_repository.dart';
import '../domain/repositories/chat_repository.dart';

/// Inyecta la implementación de chat respaldada por Supabase.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SupabaseChatRepository(ref.watch(supabaseClientProvider));
});
