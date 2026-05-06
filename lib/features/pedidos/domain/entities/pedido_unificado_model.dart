/// Identifica un pedido por la fuente desde la que se quiere consultar.
///
/// Se usa cuando el origen es el chat (sólo conocemos la solicitud) o cuando
/// el origen es la lista de pedidos aceptados (conocemos la transacción).
sealed class PedidoRef {
  const PedidoRef();

  const factory PedidoRef.porSolicitud(String solicitudId) =
      PedidoPorSolicitud;
  const factory PedidoRef.porTransaccion(String transaccionId) =
      PedidoPorTransaccion;
}

class PedidoPorSolicitud extends PedidoRef {
  final String solicitudId;
  const PedidoPorSolicitud(this.solicitudId);
}

class PedidoPorTransaccion extends PedidoRef {
  final String transaccionId;
  const PedidoPorTransaccion(this.transaccionId);
}

/// Vista unificada de un pedido para la pantalla de detalle.
///
/// Combina los datos de `solicitudes_oferta` y `transacciones` (1:1 cuando la
/// solicitud está aceptada) más el plato y la contraparte, de forma que la UI
/// no necesita conocer dos fuentes distintas.
class PedidoUnificadoModel {
  final String solicitudId;
  final String? transaccionId;
  final String? conversacionId;

  final String estadoSolicitud;
  final String? estadoTransaccion;
  final String tipo; // venta | intercambio

  final String productoId;
  final String tituloProducto;
  final String urlImagenProducto;

  final double? precioUnitario;
  final double? total;
  final int cantidad;
  final int? cantidadOfrecida;

  final String solicitanteId;
  final String propietarioId;
  final String nombreContraparte;
  final String urlAvatarContraparte;
  final double valoracionMediaContraparte;
  final int numeroValoracionesContraparte;

  final DateTime creadoEn;
  final DateTime? aceptadoEn;
  final DateTime? completadoEn;

  const PedidoUnificadoModel({
    required this.solicitudId,
    this.transaccionId,
    this.conversacionId,
    required this.estadoSolicitud,
    this.estadoTransaccion,
    required this.tipo,
    required this.productoId,
    required this.tituloProducto,
    required this.urlImagenProducto,
    this.precioUnitario,
    this.total,
    required this.cantidad,
    this.cantidadOfrecida,
    required this.solicitanteId,
    required this.propietarioId,
    required this.nombreContraparte,
    this.urlAvatarContraparte = '',
    this.valoracionMediaContraparte = 0,
    this.numeroValoracionesContraparte = 0,
    required this.creadoEn,
    this.aceptadoEn,
    this.completadoEn,
  });

  /// Devuelve el id de la contraparte respecto al usuario indicado.
  String contraparte(String usuarioId) =>
      usuarioId == solicitanteId ? propietarioId : solicitanteId;

  /// Indica si el usuario es quien envió la solicitud (rol comprador).
  bool esSolicitante(String usuarioId) => usuarioId == solicitanteId;

  /// Código humano del pedido. Usa la transacción si existe, si no la
  /// solicitud, replicando el "Pedido #YY-3821" del prototipo (se queda con
  /// los últimos 6 caracteres en mayúsculas).
  String get codigoCorto {
    final fuente = transaccionId ?? solicitudId;
    return fuente.length >= 6
        ? fuente.substring(fuente.length - 6).toUpperCase()
        : fuente.toUpperCase();
  }
}
