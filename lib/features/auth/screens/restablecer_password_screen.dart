import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/feedback/app_feedback.dart';
import '../controllers/restablecer_password_controller.dart';

/// Pantalla para validar el enlace y definir una nueva contraseña.
class RestablecerPasswordScreen extends ConsumerStatefulWidget {
  final String? tokenHash;
  final String? tipo;

  const RestablecerPasswordScreen({
    super.key,
    required this.tokenHash,
    required this.tipo,
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
      mostrarExito(context, 'Contraseña actualizada correctamente');
      context.go(RutasApp.iniciarSesion);
    } catch (error) {
      if (mounted) {
        mostrarError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estado = ref.watch(restablecerPasswordControllerProvider(_parametros));
    final paso = estado.paso;
    final validando = paso == PasoRestablecerPassword.validandoToken;
    final guardando = paso == PasoRestablecerPassword.guardandoPassword;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Image.asset(
                AppAssets.logo,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                'Restablecer contraseña',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _descripcionPorPaso(paso),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              if (paso == PasoRestablecerPassword.enlaceInvalido)
                _buildEstadoInvalido()
              else if (paso == PasoRestablecerPassword.esperandoConfirmacion)
                _buildEstadoConfirmacion()
              else if (validando)
                _buildEstadoValidando()
              else
                _buildFormulario(guardando),
            ],
          ),
        ),
      ),
    );
  }

  String _descripcionPorPaso(PasoRestablecerPassword paso) {
    switch (paso) {
      case PasoRestablecerPassword.enlaceInvalido:
        return 'Este enlace no es válido o ha caducado. Puedes volver al inicio de sesión o solicitar uno nuevo.';
      case PasoRestablecerPassword.esperandoConfirmacion:
        return 'Antes de mostrar el formulario vamos a validar el enlace de recuperación.';
      case PasoRestablecerPassword.validandoToken:
        return 'Estamos comprobando que el enlace siga activo y pertenezca a tu cuenta.';
      case PasoRestablecerPassword.formularioListo:
      case PasoRestablecerPassword.guardandoPassword:
        return 'Escribe tu nueva contraseña para completar la recuperación de tu cuenta.';
    }
  }

  Widget _buildEstadoInvalido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.link_off_rounded,
                color: Colors.orange.shade800,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'El enlace de recuperación ya no puede utilizarse. Solicita otro desde la pantalla de acceso.',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => context.go(RutasApp.iniciarSesion),
          child: const Text('Volver al inicio de sesión'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => context.go(RutasApp.recuperarPassword),
          child: const Text('Solicitar un nuevo enlace'),
        ),
      ],
    );
  }

  Widget _buildEstadoConfirmacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Colors.blue.shade800,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pulsa en continuar para validar el enlace y abrir el formulario de cambio de contraseña.',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _continuarRecuperacion,
          child: const Text('Continuar recuperación'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go(RutasApp.iniciarSesion),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _buildEstadoValidando() {
    return SizedBox(
      height: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            'Validando enlace de recuperación...',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario(bool guardando) {
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
                  labelText: 'Nueva contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarNuevaPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: guardando
                        ? null
                        : () => setState(
                              () =>
                                  _ocultarNuevaPassword = !_ocultarNuevaPassword,
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmarPasswordController,
                decoration: InputDecoration(
                  labelText: 'Repetir contraseña',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarConfirmacion
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: guardando
                        ? null
                        : () => setState(
                              () =>
                                  _ocultarConfirmacion = !_ocultarConfirmacion,
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
        ElevatedButton(
          onPressed: guardando ? null : _guardarNuevaPassword,
          child: guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Guardar nueva contraseña'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: guardando ? null : () => context.go(RutasApp.iniciarSesion),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
