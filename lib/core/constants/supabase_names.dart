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

abstract final class BucketsSupabase {
  static const imagenesProductos = 'imagenes-productos';
  static const avatares = 'avatares';
}

abstract final class RpcsSupabase {
  static const crearSolicitudOferta = 'crear_solicitud_oferta';
  static const aceptarSolicitudOferta = 'aceptar_solicitud_oferta';
  static const denegarSolicitudOferta = 'denegar_solicitud_oferta';
  static const completarTransaccion = 'completar_transaccion';
}
