import 'package:intl/intl.dart';

final NumberFormat _formatoKilometros = NumberFormat('#,##0.0', 'es_ES');

/// Presenta una distancia pensada para UI compacta de feed y mapa.
String formatearDistanciaKm(double km) {
  final distanciaSegura = km.isFinite && km > 0 ? km : 0;

  if (distanciaSegura < 1) {
    return '${(distanciaSegura * 1000).round()} m';
  }

  return '${_formatoKilometros.format(distanciaSegura)} km';
}
