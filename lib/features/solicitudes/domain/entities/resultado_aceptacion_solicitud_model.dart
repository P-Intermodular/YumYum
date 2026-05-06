/// Resultado que devuelve el backend al aceptar una solicitud.
class ResultadoAceptacionSolicitudModel {
  final String transaccionId;
  final String conversacionId;

  const ResultadoAceptacionSolicitudModel({
    required this.transaccionId,
    required this.conversacionId,
  });
}
