import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../data/repositories/supabase_auth_repository.dart';
import '../domain/repositories/auth_repository.dart';

/// Inyecta la implementación de autenticación usada por la app.
final autenticacionRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});
