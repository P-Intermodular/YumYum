/// Reúne las rutas internas de navegación de YumYum.
///
/// Incluye tanto las rutas actuales en castellano como los aliases temporales
/// heredados para mantener compatibilidad con enlaces antiguos.
abstract final class RutasApp {
  static const iniciarSesion = '/iniciar-sesion';
  static const registro = '/registro';
  static const inicio = '/inicio';
  static const mapa = '/mapa';
  static const publicar = '/publicar';
  static const pedidos = '/pedidos';
  static const perfil = '/perfil';
  static const perfilEditar = '/perfil/editar';
  static const perfilUbicacion = '/perfil/ubicacion';
  static const ajustes = '/ajustes';
  static const preferenciasNotificaciones = '/ajustes/notificaciones';
  static const recuperarPassword = '/recuperar-password';
  static const restablecerPassword = '/restablecer-password';
  static const chats = '/chats';
  static const notificaciones = '/notificaciones';
  static const guardados = '/guardados';

  static const aliasLogin = '/login';
  static const aliasSignup = '/signup';
  static const aliasFeed = '/feed';
  static const aliasMap = '/map';
  static const aliasAdd = '/add';
  static const aliasOrders = '/orders';
  static const aliasProfile = '/profile';
  static const aliasProducto = '/product/:id';
  static const aliasChatRoom = '/chat_room/:id';

  static const productoParametro = '/producto/:id';
  static const editarPlatoParametro = '/editar-plato/:id';
  static const chatParametro = '/chat/:id';
  static const transaccionParametro = '/transaccion/:id';
  static const pedidoSolicitudParametro = '/pedido/solicitud/:id';
  static const valorarParametro = '/valorar/:transaccionId';
  static const perfilUsuarioParametro = '/usuario/:id';

  /// Construye la ruta de detalle para un producto concreto.
  static String productoDetalle(String productoId) => '/producto/$productoId';

  /// Construye la ruta para editar un plato ya publicado. Reutiliza la
  /// pantalla `PublicarProductoScreen` pasándole el id en modo edición.
  static String editarPlato(String productoId) => '/editar-plato/$productoId';

  /// Construye la ruta de acceso a un chat concreto.
  static String chat(String chatId) => '/chat/$chatId';

  /// Construye la ruta de detalle de una transacción.
  static String transaccionDetalle(String id) => '/transaccion/$id';

  /// Construye la ruta de detalle del pedido cuando aún no existe transacción
  /// y solo se conoce la solicitud (estado pendiente / denegada / cancelada).
  static String pedidoPorSolicitud(String solicitudId) =>
      '/pedido/solicitud/$solicitudId';

  /// Construye la ruta para valorar una transacción completada.
  static String valorarTransaccion(String transaccionId) =>
      '/valorar/$transaccionId';

  /// Construye la ruta de perfil público de otro usuario.
  static String perfilUsuario(String usuarioId) => '/usuario/$usuarioId';

  /// Indica si una ruta puede visitarse sin sesión iniciada.
  static bool esRutaPublica(String path) {
    return path == iniciarSesion ||
        path == registro ||
        path == recuperarPassword ||
        path == restablecerPassword ||
        path == aliasLogin ||
        path == aliasSignup;
  }
}
