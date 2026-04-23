import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../data/repositories/supabase_transaccion_repository.dart';
import '../domain/repositories/transaccion_repository.dart';

final transaccionRepositoryProvider = Provider<TransaccionRepository>((ref) {
  return SupabaseTransaccionRepository(ref.watch(supabaseClientProvider));
});
