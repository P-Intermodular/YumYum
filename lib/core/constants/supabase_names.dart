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
  static const obtenerProductosCercanos = 'obtener_productos_cercanos';
}
