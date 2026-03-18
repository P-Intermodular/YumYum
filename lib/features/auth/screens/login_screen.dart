import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'test@example.com');
  final _passController = TextEditingController(text: '123456');

  void _login() async {
    await ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        context.go('/feed'); // user is logged in
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.eco, size: 80, color: Color(0xFF4CAF50)),
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
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo Demo'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _login,
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Entrar'),
              ),
              TextButton(
                onPressed: () {
                  // context.push('/signup'); // Missing signup for now but we'll add it or skip it for demo
                },
                child: const Text('¿No tienes cuenta? Regístrate'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
