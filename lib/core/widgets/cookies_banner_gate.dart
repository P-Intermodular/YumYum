import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/rutas_app.dart';
import '../preferencias/cookies_consent_provider.dart';
import 'ui/yum_button.dart';

class CookiesBannerGate extends ConsumerWidget {
  final Widget child;

  const CookiesBannerGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aceptadas = ref.watch(cookiesAceptadasProvider);
    if (aceptadas) return child;

    return Stack(
      children: [
        child,
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Usamos cookies técnicas para mejorar tu experiencia.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => context.push(RutasApp.cookies),
                    child: Text(
                      'Ver política de cookies',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  YumButton(
                    text: 'Aceptar cookies',
                    fullWidth: true,
                    onPressed: () => ref.read(cookiesAceptadasProvider.notifier).aceptar(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

