/// Valores de dominio admitidos para el tipo de oferta de un producto.
abstract final class TipoOferta {
  static const venta = 'venta';
  static const intercambio = 'intercambio';
}

/// Estados posibles de un producto dentro del ciclo de vida del marketplace.
abstract final class EstadoProducto {
  static const disponible = 'disponible';
  static const reservado = 'reservado';
  static const agotado = 'agotado';
  static const completado = 'completado';
  static const cancelado = 'cancelado';
}

/// Estados que puede atravesar una solicitud de oferta.
abstract final class EstadoSolicitud {
  static const pendiente = 'pendiente';
  static const aceptada = 'aceptada';
  static const denegada = 'denegada';
  static const autoDenegada = 'auto_denegada';
  static const cancelada = 'cancelada';
}

/// Estados visibles para una transacción ya aceptada por ambas partes.
abstract final class EstadoTransaccion {
  static const pendiente = 'pendiente';
  static const aceptada = 'aceptada';
  static const completada = 'completada';
  static const cancelada = 'cancelada';
  static const reportada = 'reportada';
}
