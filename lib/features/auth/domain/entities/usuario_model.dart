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
    this.certificacionSanitaria,
    this.esModerador = false,
    this.valoracionMedia = 0,
    this.numeroValoraciones = 0,
    this.pedidosCompletados = 0,
    this.creadoEn,
    this.latitudPredeterminada,
    this.longitudPredeterminada,
  });

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
