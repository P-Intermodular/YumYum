import 'package:latlong2/latlong.dart';

/// Representa el perfil público de un usuario dentro de YumYum.
class UsuarioModel {
  final String id;
  final String nombre;
  final String correo;
  final String urlImagenPerfil;
  final String? ciudad;
  final String? bio;
  final List<String> preferencias;

  /// Alérgenos del Anexo II declarados por el usuario en su perfil. Sirven
  /// para auto-protección en el feed (excluir platos con esos alérgenos) y
  /// como información explícita en interacciones con cocineros.
  final List<String> alergenos;

  /// Preferencias de notificaciones por categoría (`pedidos`, `mensajes`,
  /// `valoraciones`, …). El cliente filtra la bandeja y el contador según
  /// este map. Las claves no presentes se tratan como activas via el
  /// helper [puedeRecibir], así nuevas categorías futuras no silencian al
  /// usuario por accidente.
  final Map<String, bool> preferenciasNotificaciones;

  final String? certificacionSanitaria;
  final bool esModerador;
  final double valoracionMedia;
  final int numeroValoraciones;
  final int pedidosCompletados;
  final DateTime? creadoEn;
  final double? latitudPredeterminada;
  final double? longitudPredeterminada;

  const UsuarioModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.urlImagenPerfil,
    this.ciudad,
    this.bio,
    this.preferencias = const [],
    this.alergenos = const [],
    this.preferenciasNotificaciones = const {},
    this.certificacionSanitaria,
    this.esModerador = false,
    this.valoracionMedia = 0,
    this.numeroValoraciones = 0,
    this.pedidosCompletados = 0,
    this.creadoEn,
    this.latitudPredeterminada,
    this.longitudPredeterminada,
  });

  /// Indica si el usuario quiere recibir notificaciones de la categoría
  /// dada. Las categorías no listadas en el map se asumen activas para no
  /// silenciar tipos nuevos por accidente.
  bool puedeRecibir(String categoria) =>
      preferenciasNotificaciones[categoria] ?? true;

  /// Devuelve la ubicación exacta predeterminada si está configurada.
  LatLng? get ubicacionPredeterminada {
    if (latitudPredeterminada == null || longitudPredeterminada == null) {
      return null;
    }
    return LatLng(latitudPredeterminada!, longitudPredeterminada!);
  }

  /// Crea una copia parcial conservando el resto del estado actual.
  UsuarioModel copyWith({
    String? id,
    String? nombre,
    String? correo,
    String? urlImagenPerfil,
    String? ciudad,
    String? bio,
    List<String>? preferencias,
    List<String>? alergenos,
    Map<String, bool>? preferenciasNotificaciones,
    String? certificacionSanitaria,
    bool? esModerador,
    double? valoracionMedia,
    int? numeroValoraciones,
    int? pedidosCompletados,
    DateTime? creadoEn,
    double? latitudPredeterminada,
    double? longitudPredeterminada,
  }) {
    return UsuarioModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      urlImagenPerfil: urlImagenPerfil ?? this.urlImagenPerfil,
      ciudad: ciudad ?? this.ciudad,
      bio: bio ?? this.bio,
      preferencias: preferencias ?? this.preferencias,
      alergenos: alergenos ?? this.alergenos,
      preferenciasNotificaciones:
          preferenciasNotificaciones ?? this.preferenciasNotificaciones,
      certificacionSanitaria:
          certificacionSanitaria ?? this.certificacionSanitaria,
      esModerador: esModerador ?? this.esModerador,
      valoracionMedia: valoracionMedia ?? this.valoracionMedia,
      numeroValoraciones: numeroValoraciones ?? this.numeroValoraciones,
      pedidosCompletados: pedidosCompletados ?? this.pedidosCompletados,
      creadoEn: creadoEn ?? this.creadoEn,
      latitudPredeterminada:
          latitudPredeterminada ?? this.latitudPredeterminada,
      longitudPredeterminada:
          longitudPredeterminada ?? this.longitudPredeterminada,
    );
  }
}
