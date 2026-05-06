import 'package:intl/intl.dart';

/// Formatea una marca temporal como tiempo relativo corto en español.
///
/// Devuelve "ahora", "X min", "X h", "X d" para diferencias < 7 días, y
/// `dd MMM` (ej. "5 may") para fechas más antiguas. Pensado para chips,
/// notificaciones, tarjetas y cualquier dato cuyo valor exacto no aporte.
String formatearTiempoRelativo(DateTime fecha) {
  final diferencia = DateTime.now().difference(fecha);
  if (diferencia.inMinutes < 1) return 'ahora';
  if (diferencia.inMinutes < 60) return '${diferencia.inMinutes} min';
  if (diferencia.inHours < 24) return '${diferencia.inHours} h';
  if (diferencia.inDays < 7) return '${diferencia.inDays} d';
  return DateFormat('d MMM', 'es').format(fecha);
}
