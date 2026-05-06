import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';

/// Punto de entrada de YumYum.
///
/// Inicializa Flutter, comprueba que la configuración de Supabase esté
/// disponible y arranca la aplicación dentro de un [ProviderScope].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Carga los símbolos de fecha en español para que `DateFormat(..., 'es')`
  // funcione (formateo de meses, días de la semana, etc.).
  Intl.defaultLocale = 'es';
  await initializeDateFormatting('es', null);

  if (!SupabaseConfig.isConfigured) {
    runApp(const SupabaseConfigMissingApp());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: false,
    ),
  );

  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,
      child: const YumYumApp(),
    ),
  );
}

/// Widget raíz de la aplicación.
///
/// Resuelve el router desde Riverpod para que los cambios de autenticación
/// actualicen la navegación de forma reactiva.
class YumYumApp extends ConsumerWidget {
  const YumYumApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'YumYum',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

/// Pantalla de respaldo cuando faltan las variables de entorno de Supabase.
class SupabaseConfigMissingApp extends StatelessWidget {
  const SupabaseConfigMissingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YumYum',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Faltan SUPABASE_URL y SUPABASE_ANON_KEY. '
                'Ejecuta Flutter con --dart-define para conectar YumYum a Supabase.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
