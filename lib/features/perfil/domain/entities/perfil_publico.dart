/// Vista pública del perfil de otro usuario.
///
/// Solo expone los campos que cualquier usuario autenticado puede ver, sin
/// datos privados como email, certificación, ubicación o preferencias
/// dietéticas.
class PerfilPublico {
  final String id;
  final String nombre;
  final String urlAvatar;
  final String? ciudad;
  final String? bio;
  final double valoracionMedia;
  final int numeroValoraciones;
  final int pedidosCompletados;
  final DateTime? creadoEn;

  const PerfilPublico({
    required this.id,
    required this.nombre,
    required this.urlAvatar,
    this.ciudad,
    this.bio,
    this.valoracionMedia = 0,
    this.numeroValoraciones = 0,
    this.pedidosCompletados = 0,
    this.creadoEn,
  });
}
