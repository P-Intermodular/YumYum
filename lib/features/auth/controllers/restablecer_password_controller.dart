import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_repository_provider.dart';
import 'auth_controller.dart';

/// Etapas posibles del flujo de restablecimiento de contraseña.
enum PasoRestablecerPassword {
  enlaceInvalido,
  esperandoConfirmacion,
  validandoToken,
  formularioListo,
  guardandoPassword,
}

/// Parámetros recibidos desde la ruta de recuperación.
class ParametrosRestablecerPassword {
  final String? tokenHash;
  final String? tipo;

  const ParametrosRestablecerPassword({
    required this.tokenHash,
    required this.tipo,
  });

  /// Indica si la URL contiene los parámetros mínimos del flujo recovery.
  bool get esRecoveryValido =>
      tokenHash != null && tokenHash!.isNotEmpty && tipo == 'recovery';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParametrosRestablecerPassword &&
        other.tokenHash == tokenHash &&
        other.tipo == tipo;
  }

  @override
  int get hashCode => Object.hash(tokenHash, tipo);
}

/// Estado serializable del flujo de restablecimiento.
class EstadoRestablecerPassword {
  final PasoRestablecerPassword paso;
  final String? tokenHash;
  final String? tipo;

  const EstadoRestablecerPassword({
    required this.paso,
    required this.tokenHash,
    required this.tipo,
  });

  /// Devuelve una copia con el paso actualizado.
  EstadoRestablecerPassword copyWith({
    PasoRestablecerPassword? paso,
  }) {
    return EstadoRestablecerPassword(
      paso: paso ?? this.paso,
      tokenHash: tokenHash,
      tipo: tipo,
    );
  }
}

/// Gestiona la validación y cierre del flujo recovery.
final restablecerPasswordControllerProvider = StateNotifierProvider.autoDispose
    .family<RestablecerPasswordController, EstadoRestablecerPassword,
        ParametrosRestablecerPassword>((ref, parametros) {
  return RestablecerPasswordController(ref, parametros);
});

/// Orquesta la validación del token hash y el guardado de la nueva contraseña.
class RestablecerPasswordController
    extends StateNotifier<EstadoRestablecerPassword> {
  final Ref _ref;
  final ParametrosRestablecerPassword _parametros;

  RestablecerPasswordController(this._ref, this._parametros)
      : super(
          _crearEstadoInicial(_parametros),
        );

  /// Construye el estado inicial a partir de los parámetros de la URL.
  static EstadoRestablecerPassword _crearEstadoInicial(
    ParametrosRestablecerPassword parametros,
  ) {
    return EstadoRestablecerPassword(
      paso: parametros.esRecoveryValido
          ? PasoRestablecerPassword.esperandoConfirmacion
          : PasoRestablecerPassword.enlaceInvalido,
      tokenHash: parametros.tokenHash,
      tipo: parametros.tipo,
    );
  }

  /// Verifica el token hash del correo antes de mostrar el formulario.
  Future<void> validarEnlace() async {
    if (!_parametros.esRecoveryValido) {
      state = state.copyWith(paso: PasoRestablecerPassword.enlaceInvalido);
      return;
    }

    if (state.paso == PasoRestablecerPassword.validandoToken ||
        state.paso == PasoRestablecerPassword.guardandoPassword) {
      return;
    }

    state = state.copyWith(paso: PasoRestablecerPassword.validandoToken);
    try {
      await _ref
          .read(autenticacionRepositoryProvider)
          .verificarRecuperacionPassword(_parametros.tokenHash!);
      state = state.copyWith(paso: PasoRestablecerPassword.formularioListo);
    } catch (_) {
      state = state.copyWith(paso: PasoRestablecerPassword.enlaceInvalido);
      rethrow;
    }
  }

  /// Guarda la nueva contraseña dentro de una sesión recovery ya validada.
  Future<void> guardarNuevaPassword(String nuevaPassword) async {
    if (state.paso != PasoRestablecerPassword.formularioListo) return;

    state = state.copyWith(paso: PasoRestablecerPassword.guardandoPassword);
    try {
      await _ref
          .read(autenticacionProvider.notifier)
          .restablecerPassword(nuevaPassword);
      state = state.copyWith(paso: PasoRestablecerPassword.enlaceInvalido);
    } catch (_) {
      state = state.copyWith(paso: PasoRestablecerPassword.formularioListo);
      rethrow;
    }
  }
}
