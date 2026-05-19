import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/controllers/auth_controller.dart';
import '../../services/ia_service.dart';
import '../../theme/yum_colors.dart';

/// FAB persistente del asistente IA. Se monta en el shell autenticado
/// (`PrincipalScreen`) y abre un bottom sheet con un campo de texto que
/// envía la consulta a la Edge Function `asistente-ia` de Supabase (ver
/// [IAService]). La integración con Gemini vive ahí, no en el cliente.
///
/// Originalmente venía de la rama `origin/César`; aquí adaptamos:
/// - mismo gradient de luminosidad que la cabecera del perfil
///   (`cabecera_perfil.dart`) para dar continuidad visual a las superficies
///   "marca" de la app y diferenciarlo del FAB '+' plano del bottom nav,
/// - el `userId` real desde `autenticacionProvider` en lugar de hardcoded,
/// - `useRootNavigator: true` en lugar de inyectar un `rootNavigatorKey`
///   global, evitando acoplar el router a este componente.
class BotonIAGlobal extends StatelessWidget {
  const BotonIAGlobal({super.key});

  Future<void> _abrirModal(BuildContext context) async {
    final colors = context.yumColors;
    await showModalBottomSheet<void>(
      context: context,
      // Asegura que el sheet aparezca por encima del bottom nav del shell.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: colors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        // Empuja el sheet por encima del teclado en web/móvil.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: const _FormularioIa(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    // FloatingActionButton no admite gradient como backgroundColor, así que
    // construimos manualmente un contenedor 56×56 con la misma apariencia
    // (sombra + radius + tap ripple). El degrado del primario al dorado
    // sugiere "magia" típica de los CTAs de IA en apps modernas, sin salir
    // de la paleta del tema.
    return Tooltip(
      message: 'Asistente IA',
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            // Mismo gradient que la cabecera del perfil
            // (`cabecera_perfil.dart`): nos quedamos en el hue cálido del
            // primario y solo modulamos la luminosidad hacia cream. Da
            // continuidad visual con el resto de superficies "marca" sin
            // virar a marrón en la mezcla intermedia.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.terracotta,
                Color.lerp(colors.terracotta, colors.cream, 0.35)!,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.terracotta.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _abrirModal(context),
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.paper,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Formulario interno del bottom sheet. Mantiene el estado de carga y de
/// texto, llama a [IAService] y enruta el intent devuelto.
class _FormularioIa extends ConsumerStatefulWidget {
  const _FormularioIa();

  @override
  ConsumerState<_FormularioIa> createState() => _FormularioIaState();
}

class _FormularioIaState extends ConsumerState<_FormularioIa> {
  final TextEditingController _controller = TextEditingController();
  bool _cargando = false;

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    final usuario = ref.read(autenticacionProvider).valueOrNull;
    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para usar el asistente.'),
        ),
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      final respuesta = await IAService.procesarTexto(texto, usuario.id);
      if (!mounted) return;
      Navigator.pop(context);

      // TODO: orquestar la navegación a publicar / filtrado del feed según
      // `respuesta['accion']`. Por ahora dejamos el debugPrint para no
      // bloquear la mezcla con la rama de César.
      debugPrint('IA respuesta: $respuesta');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No pude contactar al asistente: $e'),
          backgroundColor: Theme.of(context)
              .extension<YumColors>()
              ?.terracottaDeep,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Qué necesitas hacer hoy?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 3,
              enabled: !_cargando,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviar(),
              decoration: InputDecoration(
                hintText: 'Ej: Quiero compartir 2 raciones de paella…',
                suffixIcon: _cargando
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send_rounded),
                        color: colors.oliveDeep,
                        onPressed: _enviar,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
