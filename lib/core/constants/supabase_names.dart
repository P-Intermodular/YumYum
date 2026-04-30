/// Nombres de tablas públicas que usa la app al consultar Supabase.
abstract final class TablasSupabase {
  static const perfiles = 'perfiles';
  static const productos = 'productos';
  static const imagenesProducto = 'imagenes_producto';
  static const solicitudesOferta = 'solicitudes_oferta';
  static const transacciones = 'transacciones';
  static const conversaciones = 'conversaciones';
  static const mensajes = 'mensajes';
  static const valoraciones = 'valoraciones';
  static const reportes = 'reportes';
  static const notificaciones = 'notificaciones';
}

/// Buckets de Storage definidos por YumYum para recursos subidos por usuarios.
abstract final class BucketsSupabase {
  static const imagenesProductos = 'imagenes-productos';
  static const avatares = 'avatares';
}

/// Procedimientos remotos expuestos por la base de datos.
///
/// Se usan para concentrar operaciones críticas que deben ejecutarse de forma
/// atómica dentro de PostgreSQL.
abstract final class RpcsSupabase {
  static const crearSolicitudOferta = 'crear_solicitud_oferta';
  static const aceptarSolicitudOferta = 'aceptar_solicitud_oferta';
  static const denegarSolicitudOferta = 'denegar_solicitud_oferta';
  static const completarTransaccion = 'completar_transaccion';
  static const obtenerMiPerfil = 'obtener_mi_perfil';
  static const obtenerProductosCercanos = 'obtener_productos_cercanos';
  static const obtenerUbicacionExactaProducto =
      'obtener_ubicacion_exacta_producto';
  static const cancelarSolicitudOferta = 'cancelar_solicitud_oferta';
  static const cancelarTransaccion = 'cancelar_transaccion';
}
