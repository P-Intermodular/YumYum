import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cliente del asistente IA de YumYum.
///
/// El backend que atiende estas peticiones es un servicio Node.js externo
/// (no incluido en este repositorio): debe estar corriendo en
/// `localhost:3000` durante el desarrollo. Si no está disponible, el FAB
/// devolverá un error de red que la UI muestra como SnackBar — sin romper
/// el resto de la app.
class IAService {
  /// Resuelve el host del backend según la plataforma.
  ///
  /// En el emulador Android `localhost` apunta al propio emulador, no al
  /// host de desarrollo. Por eso usamos `10.0.2.2`, el alias estándar al
  /// host. En web y desktop bastan `localhost`.
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  /// Envía la entrada del usuario al backend para análisis de intención.
  ///
  /// El backend devuelve un JSON con `accion` (`'publicar'` | `'buscar'` |
  /// otra) y datos auxiliares. El cliente solo deserializa y propaga la
  /// respuesta — la orquestación del intent (navegar a publicar, filtrar
  /// el feed) se hace en la capa de UI.
  static Future<Map<String, dynamic>> procesarTexto(
    String texto,
    String usuarioId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/procesar-parte-ia'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'texto': texto,
          'usuario': usuarioId,
          'rol': 'USER',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // El backend documentado devuelve `{ "error": "..." }` en errores
      // de validación; lo propagamos para que la UI lo muestre.
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          body['error'] as String? ??
              'Error de servidor HTTP: ${response.statusCode}',
        );
      } on FormatException {
        throw Exception('Error de servidor HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo de red al contactar la IA: $e');
    }
  }
}
