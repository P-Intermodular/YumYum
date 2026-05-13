import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_decor.dart';

/// Pantalla de creación de cuenta.
class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _ocultarPassword = true;
  bool _aceptaLegal = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valida el formulario y delega el registro en [AutenticacionNotifier].
  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceptaLegal) {
      mostrarError(
        context,
        Exception('Debes aceptar los Términos y la Política de Privacidad.'),
      );
      return;
    }

    await ref.read(autenticacionProvider.notifier).registrarUsuario(
          _nombreController.text.trim(),
          _correoController.text.trim(),
          _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    ref.listen(autenticacionProvider, (previous, next) {
      if (!next.enRecuperacion && next.usuario.value != null) {
        context.go(RutasApp.inicio);
      } else if (next.usuario.hasError) {
        mostrarError(context, next.usuario.error!);
      }
    });

    final estadoAutenticacion = ref.watch(autenticacionProvider);
    final cargando = estadoAutenticacion.isLoading;

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
              top: 140,
              left: -60,
              size: 220,
              color: colors.mustard.withValues(alpha: 0.20),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CabeceraAuth(
                        titulo: 'Crear cuenta',
                        subtitulo: 'Únete a la comunidad de comida casera de tu barrio.',
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          hintText: 'Ej. María García',
                          prefixIcon: Icon(Icons.person_outline, color: colors.inkSoft, size: 20),
                        ),
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Introduce tu nombre'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _correoController,
                        decoration: InputDecoration(
                          hintText: 'Ej. hola@vecindario.es',
                          prefixIcon: Icon(Icons.mail_outline, color: colors.inkSoft, size: 20),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: (value) => value == null || !value.contains('@')
                            ? 'Correo no válido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline, color: colors.inkSoft, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: colors.inkSoft,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _ocultarPassword = !_ocultarPassword),
                          ),
                        ),
                        obscureText: _ocultarPassword,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => cargando ? null : _registrarUsuario(),
                        validator: (value) => value == null || value.length < 6
                            ? 'Mínimo 6 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 32),
                      CheckboxListTile(
                        value: _aceptaLegal,
                        onChanged: cargando
                            ? null
                            : (value) => setState(() => _aceptaLegal = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('He leído y acepto los '),
                            GestureDetector(
                              onTap: () => context.push(RutasApp.terminos),
                              child: Text(
                                'T&C',
                                style: TextStyle(
                                  color: colors.terracotta,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Text(' y la '),
                            GestureDetector(
                              onTap: () => context.push(RutasApp.privacidad),
                              child: Text(
                                'Política de Privacidad',
                                style: TextStyle(
                                  color: colors.terracotta,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      YumButton(
                        text: cargando ? 'Creando cuenta…' : 'Registrarme',
                        fullWidth: true,
                        onPressed: cargando ? null : _registrarUsuario,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go(RutasApp.iniciarSesion),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '¿Ya tienes cuenta? ',
                                  style: TextStyle(color: colors.inkSoft, fontSize: 12),
                                ),
                                TextSpan(
                                  text: 'Inicia sesión',
                                  style: TextStyle(
                                    color: colors.terracotta,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
