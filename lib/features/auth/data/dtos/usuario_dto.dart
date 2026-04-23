import '../../domain/entities/usuario_model.dart';

abstract final class UsuarioDto {
  static UsuarioModel desdePerfil(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as String,
      nombre: (json['nombre'] as String?)?.trim().isNotEmpty == true
          ? json['nombre'] as String
          : 'Usuario YumYum',
      correo: json['email'] as String? ?? '',
      urlImagenPerfil:
          (json['url_avatar'] as String?)?.trim().isNotEmpty == true
              ? json['url_avatar'] as String
              : 'https://i.pravatar.cc/150?u=${json['id']}',
      ciudad: json['ciudad'] as String?,
      preferencias: (json['preferencias'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      certificacionSanitaria: json['certificacion_sanitaria'] as String?,
      esModerador: json['es_moderador'] as bool? ?? false,
      valoracionMedia: _toDouble(json['valoracion_media']),
      numeroValoraciones: json['numero_valoraciones'] as int? ?? 0,
    );
  }

  static Map<String, dynamic> aActualizacionPerfil(UsuarioModel usuario) {
    return {
      'nombre': usuario.nombre,
      'url_avatar': usuario.urlImagenPerfil,
      'ciudad': usuario.ciudad,
      'preferencias': usuario.preferencias,
      'certificacion_sanitaria': usuario.certificacionSanitaria,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
