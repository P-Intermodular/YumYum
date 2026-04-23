abstract class ReporteRepository {
  Future<void> crearReporte({
    required String reportanteId,
    required String tipoObjetivo,
    required String objetivoId,
    required String motivo,
  });
}
