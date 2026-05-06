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

    // Mensajes no leídos: los que envió la otra persona y el usuario actual
    // aún no ha marcado como leídos.
    final noLeidos = mensajesJson
        .cast<Map<String, dynamic>>()
        .where((m) =>
            m['remitente_id'] != usuarioId && m['leido_en'] == null)
        .length;

    final productoJson = json['producto'] as Map<String, dynamic>?;

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
      producto: productoJson == null ? null : _productoDesdeJson(productoJson),
      ultimoMensaje: mensajes.isEmpty ? null : mensajes.first,
      mensajesNoLeidos: noLeidos,
    );
  }

  static ProductoEnChat _productoDesdeJson(Map<String, dynamic> json) {
    final imagenes = (json['imagenes_producto'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    String urlImagen = '';
    if (imagenes.isNotEmpty) {
      // Tomamos la primera imagen ordenada por posicion ascendente.
      final ordenadas = [...imagenes]
        ..sort((a, b) =>
            (a['posicion'] as int? ?? 0).compareTo(b['posicion'] as int? ?? 0));
      urlImagen = (ordenadas.first['url_publica'] as String?) ?? '';
    }

    return ProductoEnChat(
      id: json['id'] as String,
      titulo: (json['titulo'] as String?)?.trim().isNotEmpty == true
          ? json['titulo'] as String
          : 'Plato',
      urlImagen: urlImagen,
      precio: _toDoubleOrNull(json['precio']),
      tipoOferta: (json['tipo_oferta'] as String?) ?? 'venta',
    );
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
