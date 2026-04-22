class UsuarioModel {
  final String id;
  final String nombre;
  final String correo;
  final String urlImagenPerfil;
  final String? ciudad;
  final List<String> preferencias;
  final String? certificacionSanitaria;
  final bool esModerador;
  final double valoracionMedia;
  final int numeroValoraciones;

  const UsuarioModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.urlImagenPerfil,
    this.ciudad,
    this.preferencias = const [],
    this.certificacionSanitaria,
    this.esModerador = false,
    this.valoracionMedia = 0,
    this.numeroValoraciones = 0,
  });

  factory UsuarioModel.desdePerfil(Map<String, dynamic> json) {
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

  Map<String, dynamic> aActualizacionPerfil() {
    return {
      'nombre': nombre,
      'url_avatar': urlImagenPerfil,
      'ciudad': ciudad,
      'preferencias': preferencias,
      'certificacion_sanitaria': certificacionSanitaria,
    };
  }

  UsuarioModel copyWith({
    String? id,
    String? nombre,
    String? correo,
    String? urlImagenPerfil,
    String? ciudad,
    List<String>? preferencias,
    String? certificacionSanitaria,
    bool? esModerador,
    double? valoracionMedia,
    int? numeroValoraciones,
  }) {
    return UsuarioModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      urlImagenPerfil: urlImagenPerfil ?? this.urlImagenPerfil,
      ciudad: ciudad ?? this.ciudad,
      preferencias: preferencias ?? this.preferencias,
      certificacionSanitaria:
          certificacionSanitaria ?? this.certificacionSanitaria,
      esModerador: esModerador ?? this.esModerador,
      valoracionMedia: valoracionMedia ?? this.valoracionMedia,
      numeroValoraciones: numeroValoraciones ?? this.numeroValoraciones,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
