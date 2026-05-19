import 'package:supabase_flutter/supabase_flutter.dart';

/// Representacion de un plato cercano devuelto por el asistente IA.
class ProductoSugerido {
  final String id;
  final String titulo;
  final String? descripcion;
  final String tipo;
  final num? precio;
  final String? categoria;
  final double? distanciaKm;
  final String? propietarioNombre;
  final String? propietarioAvatar;
  final String? imagenPrincipal;

  const ProductoSugerido({
    required this.id,
    required this.titulo,
    required this.tipo,
    this.descripcion,
    this.precio,
    this.categoria,
    this.distanciaKm,
    this.propietarioNombre,
    this.propietarioAvatar,
    this.imagenPrincipal,
  });

  factory ProductoSugerido.fromJson(Map<String, dynamic> json) {
    final distancia = json['distancia_km'];
    return ProductoSugerido(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      tipo: json['tipo'] as String,
      precio: json['precio'] as num?,
      categoria: json['categoria'] as String?,
      distanciaKm: distancia is num ? distancia.toDouble() : null,
      propietarioNombre: json['propietario_nombre'] as String?,
      propietarioAvatar: json['propietario_avatar'] as String?,
      imagenPrincipal: json['imagen_principal'] as String?,
    );
  }
}

/// Datos pre-rellenados que la IA propone para abrir el formulario de
/// publicar un plato.
class PrefilledPublicacion {
  final String? titulo;
  final String? descripcion;
  final String? categoria;
  final String? tipo;
  final num? precio;

  const PrefilledPublicacion({
    this.titulo,
    this.descripcion,
    this.categoria,
    this.tipo,
    this.precio,
  });

  factory PrefilledPublicacion.fromJson(Map<String, dynamic> json) {
    return PrefilledPublicacion(
      titulo: json['titulo'] as String?,
      descripcion: json['descripcion'] as String?,
      categoria: json['categoria'] as String?,
      tipo: json['tipo'] as String?,
      precio: json['precio'] as num?,
    );
  }
}

/// Accion que el asistente sugiere al cliente tras analizar la consulta.
enum AccionAsistente { buscar, publicar, info, ninguna }

AccionAsistente _accionFromString(String? valor) {
  switch (valor) {
    case 'buscar':
      return AccionAsistente.buscar;
    case 'publicar':
      return AccionAsistente.publicar;
    case 'info':
      return AccionAsistente.info;
    default:
      return AccionAsistente.ninguna;
  }
}

/// Resultado del asistente IA listo para pintar en la UI.
class RespuestaAsistente {
  final String respuesta;
  final AccionAsistente accion;
  final List<ProductoSugerido> productos;
  final PrefilledPublicacion? prefilled;

  const RespuestaAsistente({
    required this.respuesta,
    required this.accion,
    required this.productos,
    this.prefilled,
  });

  factory RespuestaAsistente.fromJson(Map<String, dynamic> json) {
    final productos = (json['productos'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ProductoSugerido.fromJson)
        .toList();
    final prefilled = json['prefilled_publicacion'] is Map<String, dynamic>
        ? PrefilledPublicacion.fromJson(
            json['prefilled_publicacion'] as Map<String, dynamic>,
          )
        : null;
    return RespuestaAsistente(
      respuesta: json['respuesta'] as String? ?? '',
      accion: _accionFromString(json['accion'] as String?),
      productos: productos,
      prefilled: prefilled,
    );
  }
}

/// Rol de un turno en la conversacion con el asistente IA.
enum RolMensaje { user, assistant }

/// Mensaje individual dentro del historial de chat que se envia a la
/// Edge Function. Solo contiene texto: los productos y la accion del
/// turno previo no se reenvian, basta con el texto natural.
class MensajeChat {
  final RolMensaje rol;
  final String texto;

  const MensajeChat({required this.rol, required this.texto});

  Map<String, dynamic> toJson() => {
        'rol': rol == RolMensaje.user ? 'user' : 'assistant',
        'texto': texto,
      };
}

/// Cliente del asistente IA de YumYum.
///
/// La logica del asistente vive en una Edge Function de Supabase
/// (`supabase/functions/asistente-ia/`). El cliente envia el historial
/// completo de la conversacion (multi-turno) y la ubicacion aproximada;
/// la funcion habla con Gemini con function calling, ejecuta busquedas
/// reales contra Supabase si hace falta y devuelve un JSON con texto
/// conversacional, accion sugerida, productos y prefilled opcional para
/// publicar.
class IAService {
  static const String _functionName = 'asistente-ia';

  /// Envia un historial de conversacion a la Edge Function. El ultimo
  /// elemento debe ser un mensaje del usuario.
  static Future<RespuestaAsistente> enviarHistorial(
    List<MensajeChat> mensajes, {
    double? latitud,
    double? longitud,
  }) async {
    if (mensajes.isEmpty) {
      throw Exception('El historial no puede estar vacio.');
    }
    try {
      final response = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: {
          'mensajes': mensajes.map((m) => m.toJson()).toList(),
          if (latitud != null && longitud != null)
            'ubicacion': {
              'latitud': latitud,
              'longitud': longitud,
            },
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return RespuestaAsistente.fromJson(data);
      }
      throw Exception('Respuesta inesperada del asistente.');
    } on FunctionException catch (e) {
      final detalle = e.details;
      if (detalle is Map && detalle['error'] is String) {
        throw Exception(detalle['error'] as String);
      }
      throw Exception('Error del asistente (codigo ${e.status}).');
    } catch (e) {
      throw Exception('Fallo de red al contactar la IA: $e');
    }
  }
}
