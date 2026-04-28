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
  passwordActualizada,
}

/// Parámetros recibidos desde la ruta de recuperación.
class ParametrosRestablecerPassword {
  final String? tokenHash;
  final String? tipo;
  final String? codigo;

  const ParametrosRestablecerPassword({
    required this.tokenHash,
    required this.tipo,
    required this.codigo,
  });

  /// Indica si la URL contiene un token hash de recovery válido.
  bool get tieneTokenHashRecovery =>
      tokenHash != null && tokenHash!.isNotEmpty && tipo == 'recovery';

  /// Indica si la URL contiene un código PKCE pendiente de intercambio.
  bool get tieneCodigoPKCE => codigo != null && codigo!.isNotEmpty;

  /// Indica si existe algún dato verificable antes de mostrar el formulario.
  bool get puedeValidarse => tieneTokenHashRecovery || tieneCodigoPKCE;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParametrosRestablecerPassword &&
        other.tokenHash == tokenHash &&
        other.tipo == tipo &&
        other.codigo == codigo;
  }

  @override
  int get hashCode => Object.hash(tokenHash, tipo, codigo);
}

/// Estado serializable del flujo de restablecimiento.
class EstadoRestablecerPassword {
  final PasoRestablecerPassword paso;
  final String? tokenHash;
  final String? tipo;
  final String? codigo;

  const EstadoRestablecerPassword({
    required this.paso,
    required this.tokenHash,
    required this.tipo,
    required this.codigo,
  });

  /// Devuelve una copia con el paso actualizado.
  EstadoRestablecerPassword copyWith({
    PasoRestablecerPassword? paso,
  }) {
    return EstadoRestablecerPassword(
      paso: paso ?? this.paso,
      tokenHash: tokenHash,
      tipo: tipo,
      codigo: codigo,
    );
  }
}

/// Gestiona la validación y cierre del flujo recovery.
final restablecerPasswordControllerProvider = StateNotifierProvider.autoDispose
    .family<RestablecerPasswordController, EstadoRestablecerPassword,
        ParametrosRestablecerPassword>((ref, parametros) {
  final enRecuperacion = ref.read(autenticacionProvider).enRecuperacion;
  return RestablecerPasswordController(ref, parametros, enRecuperacion);
});

/// Orquesta la validación del token hash y el guardado de la nueva contraseña.
class RestablecerPasswordController
    extends StateNotifier<EstadoRestablecerPassword> {
  final Ref _ref;
  final ParametrosRestablecerPassword _parametros;

  RestablecerPasswordController(
    this._ref,
    this._parametros,
    bool enRecuperacion,
  ) : super(
          crearEstadoInicialRestablecerPassword(_parametros, enRecuperacion),
        );

  /// Verifica el token hash del correo antes de mostrar el formulario.
  Future<void> validarEnlace() async {
    if (!_parametros.puedeValidarse) {
      state = state.copyWith(paso: PasoRestablecerPassword.enlaceInvalido);
      return;
    }

    if (state.paso == PasoRestablecerPassword.validandoToken ||
        state.paso == PasoRestablecerPassword.guardandoPassword) {
      return;
    }

    state = state.copyWith(paso: PasoRestablecerPassword.validandoToken);
    final autenticacion = _ref.read(autenticacionProvider.notifier);
    autenticacion.activarRecuperacionPassword();

    try {
      if (_parametros.tieneTokenHashRecovery) {
        await _ref
            .read(autenticacionRepositoryProvider)
            .verificarRecuperacionPassword(_parametros.tokenHash!);
      } else {
        await _ref
            .read(autenticacionRepositoryProvider)
            .verificarCodigoRecuperacionPassword(_parametros.codigo!);
      }
      state = state.copyWith(paso: PasoRestablecerPassword.formularioListo);
    } catch (_) {
      autenticacion.limpiarRecuperacionPassword();
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
      state = state.copyWith(paso: PasoRestablecerPassword.passwordActualizada);
    } catch (_) {
      state = state.copyWith(paso: PasoRestablecerPassword.formularioListo);
      rethrow;
    }
  }
}

/// Construye el estado inicial a partir de los parámetros de la URL y la sesión.
EstadoRestablecerPassword crearEstadoInicialRestablecerPassword(
  ParametrosRestablecerPassword parametros,
  bool enRecuperacion,
) {
  // Compatibilidad con sesiones recovery ya abiertas por enlaces antiguos.
  if (enRecuperacion) {
    return EstadoRestablecerPassword(
      paso: PasoRestablecerPassword.formularioListo,
      tokenHash: parametros.tokenHash,
      tipo: parametros.tipo,
      codigo: parametros.codigo,
    );
  }

  return EstadoRestablecerPassword(
    paso: parametros.puedeValidarse
        ? PasoRestablecerPassword.esperandoConfirmacion
        : PasoRestablecerPassword.enlaceInvalido,
    tokenHash: parametros.tokenHash,
    tipo: parametros.tipo,
    codigo: parametros.codigo,
  );
}
