abstract final class RutasApp {
  static const iniciarSesion = '/iniciar-sesion';
  static const registro = '/registro';
  static const inicio = '/inicio';
  static const mapa = '/mapa';
  static const publicar = '/publicar';
  static const pedidos = '/pedidos';
  static const perfil = '/perfil';
  static const chats = '/chats';

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
  static const chatParametro = '/chat/:id';

  static String productoDetalle(String productoId) => '/producto/$productoId';
  static String chat(String chatId) => '/chat/$chatId';

  static bool esRutaPublica(String path) {
    return path == iniciarSesion ||
        path == registro ||
        path == aliasLogin ||
        path == aliasSignup;
  }
}
