import '../../domain/entities/conversacion_model.dart';
import '../../../auth/domain/entities/usuario_model.dart';
import '../../../auth/data/dtos/usuario_dto.dart';
import 'mensaje_dto.dart';

abstract final class ConversacionDto {
  static ConversacionModel desdeSupabase(
    Map<String, dynamic> json,
    String usuarioId,
  ) {
    final esComprador = json['comprador_id'] == usuarioId;
    final participanteJson =
        json[esComprador ? 'vendedor' : 'comprador'] as Map<String, dynamic>?;
    final mensajesJson = json['mensajes'] as List<dynamic>? ?? const [];
    final mensajes = mensajesJson
        .cast<Map<String, dynamic>>()
        .map(MensajeDto.desdeSupabase)
        .toList()
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));

    return ConversacionModel(
      id: json['id'] as String,
      participante: participanteJson == null
          ? const UsuarioModel(
              id: '',
              nombre: 'Usuario YumYum',
              correo: '',
              urlImagenPerfil: 'https://i.pravatar.cc/150?u=yumyum',
            )
          : UsuarioDto.desdePerfil(participanteJson),
      ultimoMensaje: mensajes.isEmpty ? null : mensajes.first,
    );
  }
}
