import '../../domain/entities/conversacion_model.dart';

/// Traduce filas de `mensajes` entre Supabase y el dominio.
abstract final class MensajeDto {
  /// Convierte una fila persistida en [MensajeModel].
  static MensajeModel desdeSupabase(Map<String, dynamic> json) {
    return MensajeModel(
      id: json['id'] as String,
      texto: json['contenido'] as String? ?? '',
      remitenteId: json['remitente_id'] as String,
      creadoEn: DateTime.tryParse(json['creado_en']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Genera el payload mínimo necesario para insertar un mensaje.
  static Map<String, dynamic> aInsercion(
    MensajeModel mensaje,
    String conversacionId,
  ) {
    return {
      'conversacion_id': conversacionId,
      'remitente_id': mensaje.remitenteId,
      'contenido': mensaje.texto,
    };
  }
}
