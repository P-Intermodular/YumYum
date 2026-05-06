import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/ui/boton_ia_global.dart'; // Importacion del nuevo boton global

/// Punto de entrada de YumYum.
///
/// Inicializa Flutter, configura la capa de internacionalizacion,
/// verifica las credenciales de Supabase y levanta el arbol de dependencias.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Inicializacion de la configuracion regional para el formateo de fechas.
  Intl.defaultLocale = 'es';
  await initializeDateFormatting('es', null);

  // Verificacion de variables de entorno para evitar cuelgues en tiempo de ejecucion.
  if (!SupabaseConfig.isConfigured) {
    runApp(const SupabaseConfigMissingApp());
    return;
  }

  // Inicializacion del cliente de Supabase.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: false,
    ),
  );

  // Inyeccion del ProviderScope en la raiz para habilitar Riverpod en toda la app.
  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,
      child: const YumYumApp(),
    ),
  );
}

/// Widget raiz de la aplicacion cliente.
///
/// Configura el tema global y el enrutador reactivo. Ademas, intercepta el
/// renderizado principal para inyectar componentes persistentes sobre el canvas.
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
      // builder intercepta el navegador base para dibujar elementos persistentes
      // en una capa independiente a las rutas de go_router.
      builder: (context, child) {
        return Stack(
          children: [
            // Renderiza el flujo de navegacion estandar manejado por GoRouter.
            if (child != null) child,
            
            // Renderiza el boton flotante de la IA en la esquina inferior derecha,
            // respetando los margenes de seguridad del sistema operativo.
            Positioned(
              right: 16,
              bottom: 80, // Elevado para no colisionar con la barra de navegacion inferior
              child: const SafeArea(
                child: BotonIAGlobal(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Pantalla de contingencia mostrada cuando las variables de entorno 
/// requeridas para el backend no estan configuradas.
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
