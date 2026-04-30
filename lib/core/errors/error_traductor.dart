import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduce excepciones de Supabase a mensajes legibles para el usuario.
///
/// Centraliza la traducción para evitar que errores técnicos crudos
/// (PostgrestException, AuthException, StorageException) lleguen a la UI.
abstract final class ErrorTraductor {
  /// Intenta traducir [error] a un mensaje de usuario.
  ///
  /// Devuelve `null` si el error no es de un tipo reconocido; en ese caso
  /// el caller puede usar un fallback genérico.
  static String? traducir(Object error) {
    if (error is PostgrestException) return _traducirPostgrest(error);
    if (error is AuthException) return _traducirAuth(error);
    if (error is StorageException) return _traducirStorage(error);
    return null;
  }

  // ---------------------------------------------------------------------------
  // PostgrestException (RPCs, queries)
  // ---------------------------------------------------------------------------

  static String _traducirPostgrest(PostgrestException error) {
    final mensaje = error.message;

    // Errores de nuestras RPCs — ya vienen en castellano.
    if (_esErrorDeRpc(mensaje)) return mensaje;

    // Unique constraint (solicitud duplicada, etc.)
    if (error.code == '23505' || mensaje.contains('duplicate key')) {
      return 'Esta operación ya fue realizada.';
    }

    // Foreign key violation
    if (error.code == '23503') {
      return 'Uno de los datos referenciados ya no existe.';
    }

    // Permission denied / RLS
    if (error.code == '42501' || mensaje.contains('permission denied')) {
      return 'No tienes permisos para realizar esta acción.';
    }

    // Rate limit
    if (error.code == '429' ||
        mensaje.contains('rate limit') ||
        mensaje.contains('too many requests')) {
      return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
    }

    return 'Error al procesar la solicitud. Inténtalo de nuevo.';
  }

  /// Los errores lanzados con `raise exception` en nuestras RPCs ya están
  /// escritos en castellano y son legibles para el usuario.
  static bool _esErrorDeRpc(String mensaje) {
    const erroresRpc = [
      'Autenticacion requerida',
      'El producto no esta disponible',
      'No puedes solicitar tu propio producto',
      'El tipo de solicitud no coincide',
      'Las solicitudes de venta no pueden incluir producto ofrecido',
      'Las solicitudes de intercambio requieren producto ofrecido',
      'El producto ofrecido no esta disponible para intercambio',
      'Ya tienes una solicitud pendiente para este producto',
      'Solicitud no encontrada',
      'Solo el solicitante puede cancelar esta solicitud',
      'La solicitud no esta pendiente',
      'Transaccion no encontrada',
      'Solo los participantes pueden cancelar esta transaccion',
      'La transaccion no puede cancelarse desde su estado actual',
      'No tienes permiso para cambiar el estado del producto',
    ];
    return erroresRpc.any((e) => mensaje.contains(e));
  }

  // ---------------------------------------------------------------------------
  // AuthException (login, registro, recovery)
  // ---------------------------------------------------------------------------

  static String _traducirAuth(AuthException error) {
    final mensaje = error.message.toLowerCase();

    if (mensaje.contains('invalid login credentials') ||
        mensaje.contains('invalid_credentials')) {
      return 'Correo o contraseña incorrectos.';
    }

    if (mensaje.contains('email not confirmed')) {
      return 'Confirma tu correo electrónico antes de iniciar sesión.';
    }

    if (mensaje.contains('user already registered') ||
        mensaje.contains('already been registered')) {
      return 'Ya existe una cuenta con este correo.';
    }

    if (mensaje.contains('rate limit') ||
        mensaje.contains('too many requests') ||
        mensaje.contains('email rate limit')) {
      return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
    }

    if (mensaje.contains('password') && mensaje.contains('short')) {
      return 'La contraseña es demasiado corta.';
    }

    if (mensaje.contains('session') &&
        (mensaje.contains('expired') || mensaje.contains('not found'))) {
      return 'Tu sesión ha caducado. Vuelve a iniciar sesión.';
    }

    // Fallback: el mensaje original de Supabase Auth suele ser razonable.
    return error.message;
  }

  // ---------------------------------------------------------------------------
  // StorageException (subida de imágenes)
  // ---------------------------------------------------------------------------

  static String _traducirStorage(StorageException error) {
    final mensaje = error.message.toLowerCase();

    if (mensaje.contains('payload too large') ||
        mensaje.contains('file size') ||
        mensaje.contains('too large')) {
      return 'La imagen es demasiado grande. Intenta con una más pequeña.';
    }

    if (mensaje.contains('not found')) {
      return 'El archivo no se encontró.';
    }

    if (mensaje.contains('permission') || mensaje.contains('not allowed')) {
      return 'No tienes permiso para subir este archivo.';
    }

    return 'Error al subir el archivo. Inténtalo de nuevo.';
  }
}
