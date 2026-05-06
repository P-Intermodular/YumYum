import '../../domain/entities/valoracion_model.dart';

/// Traduce filas de Supabase al modelo de dominio [ValoracionModel].
abstract final class ValoracionDto {
  /// Convierte una fila de `valoraciones` con join a `perfiles` del valorador.
  static ValoracionModel desdeSupabase(Map<String, dynamic> json) {
    final valorador = json['valorador'] as Map<String, dynamic>?;

    return ValoracionModel(
      id: json['id'] as String,
      transaccionId: json['transaccion_id'] as String,
      valoradorId: json['valorador_id'] as String,
      valoradoId: json['valorado_id'] as String,
      puntuacion: json['puntuacion'] as int,
      comentario: json['comentario'] as String?,
      creadoEn: DateTime.tryParse(json['creado_en']?.toString() ?? '') ??
          DateTime.now(),
      nombreValorador: valorador?['nombre'] as String? ?? 'Usuario YumYum',
      urlAvatarValorador: valorador?['url_avatar'] as String? ?? '',
    );
  }
}
