import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente del asistente IA de YumYum.
///
/// Toda la logica del asistente vive en una Edge Function de Supabase
/// (`supabase/functions/asistente-ia/`) que es quien habla con Gemini.
/// El cliente solo invoca esa funcion: el SDK de Supabase resuelve la URL
/// del proyecto, adjunta el JWT del usuario autenticado y deserializa la
/// respuesta JSON. Asi evitamos exponer la clave de Gemini en el cliente y
/// no necesitamos un backend Node propio.
class IAService {
  static const String _functionName = 'asistente-ia';

  /// Envia la entrada del usuario a la Edge Function para analisis de
  /// intencion.
  ///
  /// La funcion devuelve un JSON con `accion` (`'publicar'` | `'buscar'` |
  /// `'desconocido'`), `resumen` y campos opcionales (`nombre`, `categoria`,
  /// `tipo`, `precio`, `descripcion`). La orquestacion del intent (navegar
  /// a publicar, filtrar el feed) se hace en la capa de UI.
  static Future<Map<String, dynamic>> procesarTexto(
    String texto,
    String usuarioId,
  ) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: {
          'texto': texto,
          'usuario': usuarioId,
          'rol': 'USER',
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw Exception('Respuesta inesperada del asistente.');
    } on FunctionException catch (e) {
      // La Edge Function devuelve `{ "error": "..." }` para errores
      // controlados (texto vacio, fallo upstream, etc.). Propagamos ese
      // mensaje para que la UI lo muestre en un SnackBar.
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
