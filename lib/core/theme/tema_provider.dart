import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferencias/preferencias_locales_provider.dart';
import 'yum_colors.dart';

const _clavePrefTema = 'tema_app';

/// Tema visual activo. Lee la preferencia persistida en `SharedPreferences`
/// al construirse y publica `YumTheme.mesaBarrio` por defecto.
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
    return YumThemeX.deId(prefs.getString(_clavePrefTema)) ??
        YumTheme.mesaBarrio;
  }

  Future<void> seleccionar(YumTheme tema) async {
    state = tema;
    await ref
        .read(preferenciasLocalesProvider)
        .setString(_clavePrefTema, tema.id);
  }
}
