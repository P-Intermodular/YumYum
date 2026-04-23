import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../data/repositories/supabase_reporte_repository.dart';
import '../domain/repositories/reporte_repository.dart';

final reporteRepositoryProvider = Provider<ReporteRepository>((ref) {
  return SupabaseReporteRepository(ref.watch(supabaseClientProvider));
});
