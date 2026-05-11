import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferencias_locales_provider.dart';

const _clavePrefAvatarPreset = 'avatar_preset';

/// Avatar predefinido elegido por el usuario (solo local).
///
/// Se usa como fallback visual cuando el perfil no tiene `urlImagenPerfil`.
final avatarPresetProvider =
    NotifierProvider<AvatarPresetController, String?>(AvatarPresetController.new);

class AvatarPresetController extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.read(preferenciasLocalesProvider);
    final value = prefs.getString(_clavePrefAvatarPreset);
    return (value == null || value.trim().isEmpty) ? null : value;
  }

  Future<void> seleccionar(String? preset) async {
    final prefs = ref.read(preferenciasLocalesProvider);
    state = (preset == null || preset.trim().isEmpty) ? null : preset;
    if (state == null) {
      await prefs.remove(_clavePrefAvatarPreset);
    } else {
      await prefs.setString(_clavePrefAvatarPreset, state!);
    }
  }
}

