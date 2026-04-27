import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/rutas_app.dart';

/// Indica si la aplicación está dentro de un flujo activo de recuperación.
final recuperacionPasswordActivaProvider =
    StateNotifierProvider<RecuperacionPasswordNotifier, bool>((ref) {
  return RecuperacionPasswordNotifier();
});

/// Sincroniza el estado de recuperación con Supabase Auth y la URL actual.
class RecuperacionPasswordNotifier extends StateNotifier<bool> {
  late final StreamSubscription<AuthState> _suscripcion;

  RecuperacionPasswordNotifier() : super(_esCallbackRecuperacion(Uri.base)) {
    _suscripcion = Supabase.instance.client.auth.onAuthStateChange.listen(
      (authState) {
        switch (authState.event) {
          case AuthChangeEvent.passwordRecovery:
            state = true;
            break;
          case AuthChangeEvent.signedOut:
            state = false;
            break;
          default:
            break;
        }
      },
    );
  }

  /// Detecta callbacks de recuperación al abrir la app directamente desde web.
  static bool _esCallbackRecuperacion(Uri uri) {
    final esRutaRestablecer = uri.path == RutasApp.restablecerPassword;
    final esCallbackAuth = uri.queryParameters.containsKey('code') ||
        uri.fragment.contains('access_token');

    return esRutaRestablecer && esCallbackAuth;
  }

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }
}
