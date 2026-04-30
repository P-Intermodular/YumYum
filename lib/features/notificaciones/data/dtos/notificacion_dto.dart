import '../../domain/entities/notificacion_model.dart';

/// Traduce filas de `notificaciones` entre Supabase y el dominio.
abstract final class NotificacionDto {
  /// Convierte una fila de la tabla `notificaciones` en [NotificacionModel].
  static NotificacionModel desdeSupabase(Map<String, dynamic> json) {
    final datosRaw = json['datos'];
    final Map<String, dynamic> datos;
    if (datosRaw is Map<String, dynamic>) {
      datos = datosRaw;
    } else if (datosRaw is Map) {
      datos = datosRaw.cast<String, dynamic>();
    } else {
      datos = const {};
    }

    return NotificacionModel(
      id: json['id'] as String,
      tipo: json['tipo'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      contenido: json['contenido'] as String? ?? '',
      datos: datos,
      leidoEn: json['leido_en'] != null
          ? DateTime.tryParse(json['leido_en'].toString())
          : null,
      creadoEn: DateTime.tryParse(json['creado_en']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
