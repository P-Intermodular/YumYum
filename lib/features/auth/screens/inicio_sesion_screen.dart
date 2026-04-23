import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/feedback/app_feedback.dart';
import '../controllers/auth_controller.dart';

class InicioSesionScreen extends ConsumerStatefulWidget {
  const InicioSesionScreen({super.key});

  @override
  ConsumerState<InicioSesionScreen> createState() => _InicioSesionScreenState();
}

class _InicioSesionScreenState extends ConsumerState<InicioSesionScreen> {
  final _correoController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: '123456');

  Future<void> _iniciarSesion() async {
    await ref.read(autenticacionProvider.notifier).iniciarSesion(
          _correoController.text.trim(),
          _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(autenticacionProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        context.go(RutasApp.inicio);
      } else if (next is AsyncError) {
        mostrarError(context, next.error);
      }
    });

    final estadoAutenticacion = ref.watch(autenticacionProvider);
    final cargando = estadoAutenticacion is AsyncLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                AppAssets.logo,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              const Text(
                'YumYum',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Intercambia y vende comida cerca de ti',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _correoController,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contrasena'),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: cargando ? null : _iniciarSesion,
                child: cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Entrar'),
              ),
              TextButton(
                onPressed: () => context.push(RutasApp.registro),
                child: const Text('No tienes cuenta? Registrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
