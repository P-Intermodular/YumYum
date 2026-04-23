/// Contrato de creación de reportes para moderación.
abstract class ReporteRepository {
  /// Registra una denuncia contra un recurso o usuario del sistema.
  Future<void> crearReporte({
    required String reportanteId,
    required String tipoObjetivo,
    required String objetivoId,
    required String motivo,
  });
}
