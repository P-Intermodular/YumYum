import '../../domain/entities/usuario_model.dart';

/// Convierte perfiles de Supabase en entidades de [UsuarioModel].
///
/// También prepara la forma de escritura del perfil cuando haya actualizaciones
/// desde la aplicación.
abstract final class UsuarioDto {
  /// Crea una entidad de dominio a partir de una fila de `perfiles`.
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
              : '',
      ciudad: json['ciudad'] as String?,
      preferencias: (json['preferencias'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      certificacionSanitaria: json['certificacion_sanitaria'] as String?,
      esModerador: json['es_moderador'] as bool? ?? false,
      valoracionMedia: _toDouble(json['valoracion_media']),
      numeroValoraciones: json['numero_valoraciones'] as int? ?? 0,
      latitudPredeterminada: json['latitud_predeterminada'] != null
          ? _toDouble(json['latitud_predeterminada'])
          : null,
      longitudPredeterminada: json['longitud_predeterminada'] != null
          ? _toDouble(json['longitud_predeterminada'])
          : null,
    );
  }

  /// Genera el payload compatible con la tabla `perfiles`.
  static Map<String, dynamic> aActualizacionPerfil(UsuarioModel usuario) {
    return {
      'nombre': usuario.nombre,
      'url_avatar': usuario.urlImagenPerfil,
      'ciudad': usuario.ciudad,
      'preferencias': usuario.preferencias,
      'certificacion_sanitaria': usuario.certificacionSanitaria,
      'latitud_predeterminada': usuario.latitudPredeterminada,
      'longitud_predeterminada': usuario.longitudPredeterminada,
    };
  }

  /// Genera el payload minimo para actualizar solo la ubicacion predeterminada.
  static Map<String, dynamic> aActualizacionUbicacion(UsuarioModel usuario) {
    return {
      'latitud_predeterminada': usuario.latitudPredeterminada,
      'longitud_predeterminada': usuario.longitudPredeterminada,
    };
  }

  /// Normaliza números que pueden llegar como `num`, `String` o `null`.
  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
