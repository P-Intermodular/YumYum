import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../data/repositories/supabase_valoracion_repository.dart';
import '../domain/repositories/valoracion_repository.dart';

/// Inyecta la implementación de valoraciones usada por la app.
final valoracionRepositoryProvider = Provider<ValoracionRepository>((ref) {
  return SupabaseValoracionRepository(ref.watch(supabaseClientProvider));
});
