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
}
