import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/feedback/app_feedback.dart';
import '../controllers/auth_controller.dart';
import '../providers/recuperacion_password_provider.dart';

/// Pantalla para definir una nueva contraseña desde el enlace del correo.
class RestablecerPasswordScreen extends ConsumerStatefulWidget {
  const RestablecerPasswordScreen({super.key});

  @override
  ConsumerState<RestablecerPasswordScreen> createState() =>
      _RestablecerPasswordScreenState();
}

class _RestablecerPasswordScreenState
    extends ConsumerState<RestablecerPasswordScreen> {
  final _nuevaPasswordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _guardando = false;
  bool _ocultarNuevaPassword = true;
  bool _ocultarConfirmacion = true;

  @override
  void dispose() {
    _nuevaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _guardarNuevaPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      await ref
          .read(autenticacionProvider.notifier)
          .restablecerPassword(_nuevaPasswordController.text.trim());

      if (!mounted) return;
      mostrarExito(context, 'Contraseña actualizada correctamente');
      context.go(RutasApp.iniciarSesion);
    } catch (error) {
      if (mounted) {
        mostrarError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recuperacionActiva = ref.watch(recuperacionPasswordActivaProvider);

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
                recuperacionActiva
                    ? 'Escribe tu nueva contraseña para completar la recuperación de tu cuenta.'
                    : 'Este enlace no es válido o ha caducado. Puedes volver al inicio de sesión o solicitar uno nuevo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              if (!recuperacionActiva) ...[
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
              ] else ...[
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
                            onPressed: _guardando
                                ? null
                                : () => setState(
                                      () => _ocultarNuevaPassword =
                                          !_ocultarNuevaPassword,
                                    ),
                          ),
                        ),
                        obscureText: _ocultarNuevaPassword,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.next,
                        enabled: !_guardando,
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
                            onPressed: _guardando
                                ? null
                                : () => setState(
                                      () => _ocultarConfirmacion =
                                          !_ocultarConfirmacion,
                                    ),
                          ),
                        ),
                        obscureText: _ocultarConfirmacion,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        enabled: !_guardando,
                        onFieldSubmitted: (_) =>
                            _guardando ? null : _guardarNuevaPassword(),
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
                  onPressed: _guardando ? null : _guardarNuevaPassword,
                  child: _guardando
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
                  onPressed: _guardando
                      ? null
                      : () => context.go(RutasApp.iniciarSesion),
                  child: const Text('Cancelar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
