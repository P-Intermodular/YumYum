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
    final solicitudJson = json['solicitud'] as Map<String, dynamic>?;
    // PostgREST puede devolver `transaccion` como objeto (al detectar el
    // UNIQUE de `transacciones.solicitud_id`) o como lista (cuando lo trata
    // como 1:N). Cubrimos ambos casos para no acoplarnos a esa heurística.
    final transaccionRaw = solicitudJson?['transaccion'];
    final transaccionId = _idDeRelacionSingular(transaccionRaw);
    final estadoTransaccion = _campoDeRelacionSingular(transaccionRaw, 'estado');

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
      solicitudId: json['solicitud_id'] as String?,
      estadoSolicitud: solicitudJson?['estado'] as String?,
      transaccionId: transaccionId,
      estadoTransaccion: estadoTransaccion,
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

  /// Extrae el `id` de una relación que PostgREST puede devolver como objeto
  /// o como lista (depende de cómo detecta la cardinalidad).
  static String? _idDeRelacionSingular(dynamic raw) =>
      _campoDeRelacionSingular(raw, 'id');

  /// Igual que [_idDeRelacionSingular] pero para cualquier campo arbitrario.
  static String? _campoDeRelacionSingular(dynamic raw, String campo) {
    if (raw is Map) {
      return raw[campo] as String?;
    }
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map) return first[campo] as String?;
    }
    return null;
  }
}
