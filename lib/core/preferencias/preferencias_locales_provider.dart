import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Inyecta la instancia de [SharedPreferences] ya inicializada en `main()`.
///
/// Se sobrescribe en el `ProviderScope` raiz con la instancia obtenida
/// mediante `SharedPreferences.getInstance()`. Tener la instancia disponible
/// de forma sincrona evita el flash inicial de tema mientras se resuelve la
/// preferencia persistida del usuario.
final preferenciasLocalesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(
    'preferenciasLocalesProvider debe sobrescribirse en main() con la '
    'instancia de SharedPreferences ya inicializada.',
  ),
);
