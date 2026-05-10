import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../providers/auth_repository_provider.dart';
import '../widgets/auth_decor.dart';

/// Pantalla para solicitar un correo de restablecimiento de contraseña.
class RecuperarPasswordScreen extends ConsumerStatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  ConsumerState<RecuperarPasswordScreen> createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState
    extends ConsumerState<RecuperarPasswordScreen> {
  final _correoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _enviando = false;
  bool _enviado = false;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _enviarRecuperacion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);
    try {
      await ref
          .read(autenticacionRepositoryProvider)
          .enviarEmailRecuperacion(_correoController.text.trim());

      if (!mounted) return;
      setState(() => _enviado = true);
    } catch (error) {
      if (mounted) mostrarError(context, error);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    return Scaffold(
      body: YumBackground(
        child: Stack(
          children: [
            OrbeGlow(
              top: -40,
              right: -40,
              size: 260,
              color: colors.terracotta.withValues(alpha: 0.15),
            ),
            OrbeGlow(
              top: 160,
              left: -60,
              size: 200,
              color: colors.mustard.withValues(alpha: 0.18),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CabeceraAuth(
                      titulo: 'Recuperar contraseña',
                      subtitulo: _enviado
                          ? 'Revisa tu bandeja de entrada y sigue las instrucciones del correo.'
                          : 'Introduce el correo con el que te registraste y te enviaremos un enlace para restablecerla.',
                    ),
                    const SizedBox(height: 32),
                    if (_enviado) ...[
                      BannerAuth(
                        tono: BannerAuthTono.exito,
                        icono: Icons.mark_email_read_rounded,
                        texto: 'Correo enviado a ${_correoController.text.trim()}',
                      ),
                      const SizedBox(height: 24),
                      YumButton(
                        text: 'Volver al inicio de sesión',
                        fullWidth: true,
                        variant: YumButtonVariant.ghost,
                        onPressed: () => context.pop(),
                      ),
                    ] else ...[
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _correoController,
                          decoration: InputDecoration(
                            hintText: 'Ej. hola@vecindario.es',
                            prefixIcon:
                                Icon(Icons.mail_outline, color: colors.inkSoft, size: 20),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: (value) =>
                              value == null || !value.contains('@')
                                  ? 'Introduce un correo válido'
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      YumButton(
                        text: _enviando ? 'Enviando…' : 'Enviar enlace',
                        fullWidth: true,
                        onPressed: _enviando ? null : _enviarRecuperacion,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () => context.pop(),
                          style: TextButton.styleFrom(foregroundColor: colors.inkSoft),
                          child: const Text('Volver'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
