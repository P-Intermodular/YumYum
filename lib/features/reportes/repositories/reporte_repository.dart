import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';

abstract class ReporteRepository {
  Future<void> crearReporte({
    required String reportanteId,
    required String tipoObjetivo,
    required String objetivoId,
    required String motivo,
  });
}

final reporteRepositoryProvider = Provider<ReporteRepository>((ref) {
  return SupabaseReporteRepository(ref.watch(supabaseClientProvider));
});

class SupabaseReporteRepository implements ReporteRepository {
  final SupabaseClient _client;

  SupabaseReporteRepository(this._client);

  @override
  Future<void> crearReporte({
    required String reportanteId,
    required String tipoObjetivo,
    required String objetivoId,
    required String motivo,
  }) async {
    await _client.from('reportes').insert({
      'reportante_id': reportanteId,
      'tipo_objetivo': tipoObjetivo,
      'objetivo_id': objetivoId,
      'motivo': motivo,
    });
  }
}
