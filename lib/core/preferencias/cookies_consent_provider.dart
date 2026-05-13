import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferencias_locales_provider.dart';

const _claveCookiesAceptadas = 'cookies_aceptadas';

final cookiesAceptadasProvider =
    NotifierProvider<CookiesConsentController, bool>(CookiesConsentController.new);

class CookiesConsentController extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(preferenciasLocalesProvider).getBool(_claveCookiesAceptadas) ?? false;
  }

  Future<void> aceptar() async {
    state = true;
    await ref.read(preferenciasLocalesProvider).setBool(_claveCookiesAceptadas, true);
  }
}

