import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../controllers/auth_controller.dart';
import '../controllers/restablecer_password_controller.dart';
import '../widgets/auth_decor.dart';

/// Pantalla para validar el enlace y definir una nueva contraseña.
class RestablecerPasswordScreen extends ConsumerStatefulWidget {
  final String? tokenHash;
  final String? tipo;
  final String? codigo;

  const RestablecerPasswordScreen({
    super.key,
    required this.tokenHash,
    required this.tipo,
    required this.codigo,
  });

  @override
  ConsumerState<RestablecerPasswordScreen> createState() =>
      _RestablecerPasswordScreenState();
}

class _RestablecerPasswordScreenState
    extends ConsumerState<RestablecerPasswordScreen> {
  final _nuevaPasswordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _ocultarNuevaPassword = true;
  bool _ocultarConfirmacion = true;

  @override
  void dispose() {
    _nuevaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  ParametrosRestablecerPassword get _parametros =>
      ParametrosRestablecerPassword(
        tokenHash: widget.tokenHash,
        tipo: widget.tipo,
        codigo: widget.codigo,
      );

  Future<void> _continuarRecuperacion() async {
    try {
      await ref
          .read(restablecerPasswordControllerProvider(_parametros).notifier)
          .validarEnlace();
    } catch (_) {
      // El propio controlador convierte el flujo en "enlace inválido".
    }
  }

  Future<void> _guardarNuevaPassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(restablecerPasswordControllerProvider(_parametros).notifier)
          .guardarNuevaPassword(_nuevaPasswordController.text.trim());

      if (!mounted) return;
      _nuevaPasswordController.clear();
      _confirmarPasswordController.clear();
    } catch (error) {
      if (mounted) {
        mostrarError(context, error);
      }
    }
  }

  Future<void> _cancelarRecuperacion() async {
    final estado = ref.read(restablecerPasswordControllerProvider(_parametros));
    final enRecuperacion = ref.read(autenticacionProvider).enRecuperacion;

    if (enRecuperacion ||
        estado.paso == PasoRestablecerPassword.formularioListo ||
        estado.paso == PasoRestablecerPassword.guardandoPassword) {
      await ref
          .read(autenticacionProvider.notifier)
          .cancelarRecuperacionPassword();
    }

    if (mounted) {
      context.go(RutasApp.iniciarSesion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final estado =
        ref.watch(restablecerPasswordControllerProvider(_parametros));
    final paso = estado.paso;
    final validando = paso == PasoRestablecerPassword.validandoToken;
    final guardando = paso == PasoRestablecerPassword.guardandoPassword;

    return Scaffold(
      body: YumBackground(
        child: Stack(
          children: [
            OrbeGlow(
              top: -50,
              right: -50,
              size: 280,
              color: colors.terracotta.withValues(alpha: 0.15),
            ),
            OrbeGlow(
              top: 160,
              left: -60,
              size: 220,
              color: colors.mustard.withValues(alpha: 0.18),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CabeceraAuth(
                      titulo: 'Restablecer contraseña',
                      subtitulo: _descripcionPorPaso(paso),
                    ),
                    const SizedBox(height: 32),
                    if (paso == PasoRestablecerPassword.enlaceInvalido)
                      _buildEstadoInvalido()
                    else if (paso == PasoRestablecerPassword.esperandoConfirmacion)
                      _buildEstadoConfirmacion()
                    else if (validando)
                      _buildEstadoValidando()
                    else if (paso == PasoRestablecerPassword.passwordActualizada)
                      _buildEstadoPasswordActualizada()
                    else
                      _buildFormulario(guardando),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _descripcionPorPaso(PasoRestablecerPassword paso) {
    switch (paso) {
      case PasoRestablecerPassword.enlaceInvalido:
        return 'Este enlace no es válido o ha caducado. Vuelve al inicio o solicita uno nuevo.';
      case PasoRestablecerPassword.esperandoConfirmacion:
        return 'Antes de mostrar el formulario vamos a validar el enlace de recuperación.';
      case PasoRestablecerPassword.validandoToken:
        return 'Estamos comprobando que el enlace siga activo y pertenezca a tu cuenta.';
      case PasoRestablecerPassword.formularioListo:
      case PasoRestablecerPassword.guardandoPassword:
        return 'Escribe tu nueva contraseña para terminar la recuperación.';
      case PasoRestablecerPassword.passwordActualizada:
        return 'Tu contraseña se ha modificado correctamente. Ya puedes iniciar sesión con tus nuevas credenciales.';
    }
  }

  Widget _buildEstadoInvalido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BannerAuth(
          tono: BannerAuthTono.atencion,
          icono: Icons.link_off_rounded,
          texto:
              'El enlace de recuperación ya no puede utilizarse. Solicita otro desde la pantalla de acceso.',
        ),
        const SizedBox(height: 24),
        YumButton(
          text: 'Solicitar un nuevo enlace',
          fullWidth: true,
          onPressed: () => context.go(RutasApp.recuperarPassword),
        ),
        const SizedBox(height: 8),
        YumButton(
          text: 'Volver al inicio de sesión',
          fullWidth: true,
          variant: YumButtonVariant.ghost,
          onPressed: () => context.go(RutasApp.iniciarSesion),
        ),
      ],
    );
  }

  Widget _buildEstadoConfirmacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BannerAuth(
          tono: BannerAuthTono.info,
          icono: Icons.verified_user_outlined,
          texto:
              'Pulsa en continuar para validar el enlace y abrir el formulario de cambio de contraseña.',
        ),
        const SizedBox(height: 24),
        YumButton(
          text: 'Continuar recuperación',
          fullWidth: true,
          onPressed: _continuarRecuperacion,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _cancelarRecuperacion,
            style: TextButton.styleFrom(
              foregroundColor: context.yumColors.inkSoft,
            ),
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoValidando() {
    final colors = context.yumColors;
    return SizedBox(
      height: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(colors.terracotta),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Validando enlace de recuperación…',
            style: TextStyle(
              color: colors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoPasswordActualizada() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BannerAuth(
          tono: BannerAuthTono.exito,
          icono: Icons.check_circle_outline_rounded,
          texto:
              'Tu contraseña se ha modificado correctamente. Vuelve al inicio de sesión para entrar con tus nuevas credenciales.',
        ),
        const SizedBox(height: 24),
        YumButton(
          text: 'Ir al inicio de sesión',
          fullWidth: true,
          onPressed: () => context.go(RutasApp.iniciarSesion),
        ),
      ],
    );
  }

  Widget _buildFormulario(bool guardando) {
    final colors = context.yumColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nuevaPasswordController,
                decoration: InputDecoration(
                  hintText: 'Nueva contraseña',
                  prefixIcon: Icon(Icons.lock_outline, color: colors.inkSoft, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarNuevaPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colors.inkSoft,
                      size: 20,
                    ),
                    onPressed: guardando
                        ? null
                        : () => setState(
                              () => _ocultarNuevaPassword = !_ocultarNuevaPassword,
                            ),
                  ),
                ),
                obscureText: _ocultarNuevaPassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                enabled: !guardando,
                validator: (value) => value == null || value.length < 6
                    ? 'Mínimo 6 caracteres'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmarPasswordController,
                decoration: InputDecoration(
                  hintText: 'Repetir contraseña',
                  prefixIcon: Icon(Icons.lock_reset_outlined, color: colors.inkSoft, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarConfirmacion
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colors.inkSoft,
                      size: 20,
                    ),
                    onPressed: guardando
                        ? null
                        : () => setState(
                              () => _ocultarConfirmacion = !_ocultarConfirmacion,
                            ),
                  ),
                ),
                obscureText: _ocultarConfirmacion,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                enabled: !guardando,
                onFieldSubmitted: (_) =>
                    guardando ? null : _guardarNuevaPassword(),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  if (value != _nuevaPasswordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        YumButton(
          text: guardando ? 'Guardando…' : 'Guardar nueva contraseña',
          fullWidth: true,
          onPressed: guardando ? null : _guardarNuevaPassword,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: guardando ? null : _cancelarRecuperacion,
            style: TextButton.styleFrom(foregroundColor: colors.inkSoft),
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }
}
