import 'package:web/web.dart' as web;

/// Mantiene el `<meta name="theme-color">` del HTML sincronizado con el tema
/// activo. Eso afecta a la barra de URL del navegador en móvil y al status
/// bar de la PWA cuando está instalada. El `manifest.json` no se puede
/// modificar en runtime — solo cubre la primera instalación.
void aplicarThemeColor(String hexColor) {
  final meta = web.document.querySelector('meta[name="theme-color"]');
  if (meta != null) {
    meta.setAttribute('content', hexColor);
  }
}
