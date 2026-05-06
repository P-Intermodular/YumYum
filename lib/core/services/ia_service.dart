import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servicio de integración con el backend para el procesamiento de IA.
/// Gestiona la conexión y resolución dinámica del host según el entorno.
class IAService {
  /// Obtiene la URL del servidor adecuada para la plataforma en ejecución.
  /// Previene fallos de CORS y enrutamiento en la compilación Web.
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  /// Envía la entrada del usuario al backend para el análisis semántico.
  /// Retorna un mapa estructurado con las directivas de acción calculadas.
  static Future<Map<String, dynamic>> procesarTexto(String texto, String usuarioId) async {
    try {
      // Endpoint ajustado a la definición original del servidor Node.js
      // para resolver la excepción HTTP 404.
      final response = await http.post(
        Uri.parse('$_baseUrl/procesar-parte-ia'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'texto': texto,
          'usuario': usuarioId, // Inyección de dependencia requerida por el backend
          'rol': 'USER',        // Rol por defecto para la validación de permisos
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Error de servidor HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo de red o serialización al contactar la IA: $e');
    }
  }
}