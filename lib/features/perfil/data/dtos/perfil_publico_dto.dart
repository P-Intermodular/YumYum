import '../../domain/entities/perfil_publico.dart';

/// Convierte la respuesta de la RPC `obtener_perfil_publico` a entidad de
/// dominio.
abstract final class PerfilPublicoDto {
  static PerfilPublico desdeRpc(Map<String, dynamic> json) {
    return PerfilPublico(
      id: json['id'] as String,
      nombre: (json['nombre'] as String?)?.trim().isNotEmpty == true
          ? json['nombre'] as String
          : 'Usuario YumYum',
      urlAvatar: (json['url_avatar'] as String?) ?? '',
      ciudad: json['ciudad'] as String?,
      bio: json['bio'] as String?,
      valoracionMedia: _toDouble(json['valoracion_media']),
      numeroValoraciones: json['numero_valoraciones'] as int? ?? 0,
      pedidosCompletados: json['pedidos_completados'] as int? ?? 0,
      creadoEn: _toDateTime(json['creado_en']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
