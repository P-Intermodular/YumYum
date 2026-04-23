abstract final class TipoOferta {
  static const venta = 'venta';
  static const intercambio = 'intercambio';
}

abstract final class EstadoProducto {
  static const disponible = 'disponible';
  static const reservado = 'reservado';
  static const completado = 'completado';
  static const cancelado = 'cancelado';
}

abstract final class EstadoSolicitud {
  static const pendiente = 'pendiente';
  static const aceptada = 'aceptada';
  static const denegada = 'denegada';
  static const autoDenegada = 'auto_denegada';
  static const cancelada = 'cancelada';
}

abstract final class EstadoTransaccion {
  static const pendiente = 'pendiente';
  static const aceptada = 'aceptada';
  static const completada = 'completada';
  static const cancelada = 'cancelada';
  static const reportada = 'reportada';
}
