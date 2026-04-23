import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_names.dart';
import '../../domain/repositories/reporte_repository.dart';

/// Implementación de [ReporteRepository] respaldada por Supabase.
class SupabaseReporteRepository implements ReporteRepository {
  final SupabaseClient _client;

  SupabaseReporteRepository(this._client);

  @override

  /// Inserta una denuncia en la tabla `reportes`.
  Future<void> crearReporte({
    required String reportanteId,
    required String tipoObjetivo,
    required String objetivoId,
    required String motivo,
  }) async {
    await _client.from(TablasSupabase.reportes).insert({
      'reportante_id': reportanteId,
      'tipo_objetivo': tipoObjetivo,
      'objetivo_id': objetivoId,
      'motivo': motivo,
    });
  }
}
