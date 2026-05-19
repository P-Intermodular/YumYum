import 'package:supabase_flutter/supabase_flutter.dart';


class IAService {
  /// Envía la entrada del usuario a la Edge Function de Supabase para el análisis semántico.
  static Future<Map<String, dynamic>> procesarTexto(String texto, String usuarioId) async {
    try {
      // Invocamos la Edge Function llamada 'procesar_ia'
      final response = await Supabase.instance.client.functions.invoke(
        'procesar_ia',
        body: {
          'texto': texto,
          'usuario': usuarioId,
          'rol': 'USER',
        },
      );

      // Si el código HTTP es 200 (OK), devolvemos el JSON parseado.
      if (response.status == 200) {
        // Supabase functions.invoke ya devuelve la data parseada si es JSON.
        return response.data as Map<String, dynamic>;
      } else {
        // Si hay error controlado desde la función
        final errorMsg = response.data['error'] ?? 'Error desconocido en Edge Function';
        throw Exception('Fallo en el servidor: $errorMsg');
      }
    } catch (e) {
      if (e is FunctionException) {
        throw Exception('Error de ejecución en Edge Function: ${e.reasonPhrase}');
      }
      throw Exception('Fallo de red al contactar con la IA: $e');
    }
  }
}