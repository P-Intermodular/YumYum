import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../data/repositories/supabase_solicitud_oferta_repository.dart';
import '../domain/repositories/solicitud_oferta_repository.dart';

final solicitudOfertaRepositoryProvider =
    Provider<SolicitudOfertaRepository>((ref) {
  return SupabaseSolicitudOfertaRepository(ref.watch(supabaseClientProvider));
});
