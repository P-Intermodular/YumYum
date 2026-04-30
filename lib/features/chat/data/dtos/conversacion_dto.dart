import '../../domain/entities/conversacion_model.dart';
import '../../../auth/domain/entities/usuario_model.dart';
import '../../../auth/data/dtos/usuario_dto.dart';
import 'mensaje_dto.dart';

/// Convierte conversaciones enriquecidas de Supabase en entidades de dominio.
abstract final class ConversacionDto {
  /// Resuelve la contraparte visible y el último mensaje útil para la bandeja.
  static ConversacionModel desdeSupabase(
    Map<String, dynamic> json,
    String usuarioId,
  ) {
    final esSolicitante = json['solicitante_id'] == usuarioId;
    final participanteJson = json[esSolicitante ? 'propietario' : 'solicitante']
        as Map<String, dynamic>?;
    final mensajesJson = json['mensajes'] as List<dynamic>? ?? const [];
    final mensajes = mensajesJson
        .cast<Map<String, dynamic>>()
        .map(MensajeDto.desdeSupabase)
        .toList()
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));

    return ConversacionModel(
      id: json['id'] as String,
      // La lista de chats siempre debe mostrar "la otra persona", nunca al
      // propio usuario autenticado.
      participante: participanteJson == null
          ? const UsuarioModel(
              id: '',
              nombre: 'Usuario YumYum',
              correo: '',
              urlImagenPerfil: '',
            )
          : UsuarioDto.desdePerfil(participanteJson),
      ultimoMensaje: mensajes.isEmpty ? null : mensajes.first,
    );
  }
}
