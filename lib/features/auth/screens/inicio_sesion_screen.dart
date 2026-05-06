import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../controllers/auth_controller.dart';

/// Pantalla de acceso para usuarios ya registrados.
class InicioSesionScreen extends ConsumerStatefulWidget {
  const InicioSesionScreen({super.key});

  @override
  ConsumerState<InicioSesionScreen> createState() => _InicioSesionScreenState();
}

class _InicioSesionScreenState extends ConsumerState<InicioSesionScreen> {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(autenticacionProvider.notifier).iniciarSesion(
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
            // Orbes decorativos de fondo con efecto glow
            Positioned(
              top: -40,
              right: -40,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.terracotta.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: -50,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.mustard.withValues(alpha: 0.20),
                  ),
                ),
              ),
            ),
            
            // Contenido principal
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header con Logo
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'YumYum',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 40),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 96),
                      
                      // Titulares
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Comida '),
                            TextSpan(
                              text: 'casera',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: colors.terracotta,
                              ),
                            ),
                            const TextSpan(text: '\nde tu barrio.'),
                          ],
                        ),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 40,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Descubre, comparte e intercambia platos cocinados con cariño por vecinos reales.',
                        style: TextStyle(color: colors.inkSoft, fontSize: 14),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Formulario
                      TextFormField(
                        controller: _correoController,
                        decoration: InputDecoration(
                          hintText: 'hola@vecindario.es',
                          prefixIcon: Icon(Icons.mail_outline, color: colors.inkSoft, size: 20),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: (value) => value == null || !value.contains('@')
                            ? 'Introduce un correo válido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: '••••••••',
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
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => cargando ? null : _iniciarSesion(),
                        validator: (value) => value == null || value.length < 6
                            ? 'Mínimo 6 caracteres'
                            : null,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Recuperar contraseña
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push(RutasApp.recuperarPassword),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.inkSoft,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Botón Entrar
                      YumButton(
                        text: cargando ? 'Entrando...' : 'Entrar',
                        fullWidth: true,
                        onPressed: cargando ? null : _iniciarSesion,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Separador
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: colors.line)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'o continúa con',
                              style: TextStyle(color: colors.inkSoft, fontSize: 12),
                            ),
                          ),
                          Expanded(child: Container(height: 1, color: colors.line)),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Botones sociales
                      Row(
                        children: [
                          Expanded(
                            child: _SocialButton(
                              icon: 'G',
                              text: 'Google',
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SocialButton(
                              icon: '',
                              text: 'Apple',
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Crear cuenta
                      Center(
                        child: GestureDetector(
                          onTap: () => context.push(RutasApp.registro),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '¿Aún no estás? ',
                                  style: TextStyle(color: colors.inkSoft, fontSize: 12),
                                ),
                                TextSpan(
                                  text: 'Crea tu cuenta',
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

class _SocialButton extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colors.ink,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                icon,
                style: TextStyle(color: colors.paper, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(color: colors.ink, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
