import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferencias/preferencias_locales_provider.dart';
import 'theme_color_web.dart';
import 'yum_colors.dart';

const _clavePrefTema = 'tema_app';

/// Tema visual activo. Lee la preferencia persistida en `SharedPreferences`
/// al construirse y publica `YumTheme.huertoModerno` por defecto.
///
/// El cambio de tema es inmediato: `MaterialApp.router.theme` watchea este
/// provider, asi que cualquier `seleccionar(...)` desencadena un rebuild
/// global con la nueva paleta.
final temaProvider =
    NotifierProvider<TemaController, YumTheme>(TemaController.new);

class TemaController extends Notifier<YumTheme> {
  @override
  YumTheme build() {
    final prefs = ref.read(preferenciasLocalesProvider);
    final tema = YumThemeX.deId(prefs.getString(_clavePrefTema)) ??
        YumTheme.huertoModerno;
    // Sincroniza el meta theme-color de la PWA con el tema cargado al
    // arrancar. En no-web es no-op (conditional import).
    aplicarThemeColor(_hexThemeColor(tema));
    return tema;
  }

  Future<void> seleccionar(YumTheme tema) async {
    state = tema;
    aplicarThemeColor(_hexThemeColor(tema));
    await ref
        .read(preferenciasLocalesProvider)
        .setString(_clavePrefTema, tema.id);
  }

  /// Convierte el `cream` del tema en su hex `#RRGGBB` para escribirlo en
  /// el meta theme-color. Usamos cream (no terracotta) porque coincide con
  /// el `scaffoldBackgroundColor` real de la app — la barra del navegador
  /// se funde con el fondo y el contenido parece extenderse infinitamente
  /// hacia arriba en la PWA.
  String _hexThemeColor(YumTheme tema) {
    final color = tema.colores.cream;
    final r = (color.r * 255).round() & 0xff;
    final g = (color.g * 255).round() & 0xff;
    final b = (color.b * 255).round() & 0xff;
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }
}

