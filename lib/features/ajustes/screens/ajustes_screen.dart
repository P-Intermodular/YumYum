import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/tema_provider.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/ui/yum_app_bar.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/domain/entities/usuario_model.dart';
import '../../auth/providers/auth_repository_provider.dart';
import '../widgets/ajustes_grupo.dart';
import '../widgets/ajustes_tile.dart';
import '../widgets/selector_tema_bottom_sheet.dart';

/// Hub de gestión de cuenta y preferencias.
///
/// Sigue la organización del `SettingsScreen` de prototipo-figma: un header
/// resumen de cuenta, secciones agrupadas (Cuenta / Preferencias), y un cierre
/// de sesión con la versión de la app al pie.
class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(autenticacionProvider).value;
    final colors = context.yumColors;

    if (usuario == null) {
      return Scaffold(
        backgroundColor: colors.cream,
        appBar: const YumAppBar(title: 'Ajustes', showBack: true),
        body: const Center(child: Text('No has iniciado sesión')),
      );
    }

    return Scaffold(
      appBar: const YumAppBar(title: 'Ajustes', showBack: true),
      body: YumBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _buildHeaderCuenta(context, usuario),
            const SizedBox(height: 18),
            AjustesGrupo(
              titulo: 'Cuenta',
              children: [
                AjustesTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notificaciones',
                  onTap: () =>
                      context.push(RutasApp.preferenciasNotificaciones),
                ),
                AjustesTile(
                  icon: Icons.location_on_outlined,
                  label: 'Ubicación',
                  hint: _hintUbicacion(usuario),
                  onTap: () => context.push(RutasApp.perfilUbicacion),
                ),
                AjustesTile(
                  icon: Icons.lock_reset_rounded,
                  label: 'Cambiar contraseña',
                  onTap: () => _solicitarCambioPassword(
                    context,
                    ref,
                    usuario.correo,
                  ),
                  ultimo: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AjustesGrupo(
              titulo: 'Apariencia',
              children: [
                AjustesTile(
                  icon: Icons.palette_outlined,
                  label: 'Tema',
                  hint: ref.watch(temaProvider).etiqueta,
                  onTap: () => mostrarSelectorTema(context),
                  ultimo: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AjustesGrupo(
              titulo: 'Acerca de',
              children: [
                AjustesTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Sobre YumYum',
                  onTap: () => _mostrarSobreYumYum(context),
                  ultimo: true,
                ),
              ],
            ),
            const SizedBox(height: 28),
            YumButton(
              text: 'Cerrar sesión',
              fullWidth: true,
              variant: YumButtonVariant.ghost,
              icon: const Icon(Icons.logout_rounded),
              fgColor: colors.terracottaDeep,
              onPressed: () => _cerrarSesion(context, ref),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'YumYum v1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCuenta(BuildContext context, UsuarioModel usuario) {
    final colors = context.yumColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AvatarUsuario(
            nombre: usuario.nombre,
            identificadorColor: usuario.id,
            urlImagen: usuario.urlImagenPerfil,
            radius: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nombre,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  usuario.correo,
                  style: TextStyle(
                    color: colors.inkSoft,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          YumButton(
            text: 'Editar',
            variant: YumButtonVariant.ghost,
            onPressed: () => context.push(RutasApp.perfilEditar),
          ),
        ],
      ),
    );
  }

  String _hintUbicacion(UsuarioModel usuario) {
    final ciudad = usuario.ciudad?.trim();
    if (ciudad != null && ciudad.isNotEmpty) return ciudad;
    if (usuario.ubicacionPredeterminada != null) return 'Punto fijado';
    return 'Sin indicar';
  }

  /// Diálogo de "Cambiar contraseña" reutilizando el flujo de recuperación.
  /// Más seguro que pedir la nueva contraseña aquí: el backend envía un
  /// email al correo del usuario con un enlace para elegirla.
  Future<void> _solicitarCambioPassword(
    BuildContext context,
    WidgetRef ref,
    String correo,
  ) async {
    final colors = context.yumColors;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.line),
        ),
        title: Text(
          'Cambiar contraseña',
          style: TextStyle(color: colors.ink, fontSize: 18),
        ),
        content: Text(
          'Te enviaremos un email a $correo para que puedas elegir una nueva '
          'contraseña. Sigue el enlace en cuanto lo recibas.',
          style: TextStyle(color: colors.inkSoft, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: colors.inkSoft),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: colors.terracottaDeep),
            child: const Text('Enviar email'),
          ),
        ],
      ),
    );

    if (confirmado != true || !context.mounted) return;

    try {
      await ref
          .read(autenticacionRepositoryProvider)
          .enviarEmailRecuperacion(correo);
      if (!context.mounted) return;
      mostrarExito(context, 'Email enviado a $correo');
    } catch (error) {
      if (context.mounted) mostrarError(context, error);
    }
  }

  /// Diálogo "Sobre YumYum" con marca, versión y tagline. Patrón estándar
  /// en cualquier app real; da carácter sin tocar BD ni red.
  Future<void> _mostrarSobreYumYum(BuildContext context) async {
    final colors = context.yumColors;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.line),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.terracotta.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_dining_rounded,
                color: colors.terracottaDeep,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'YumYum',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'v1.0.0',
              style: TextStyle(color: colors.inkSoft, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Hecho con ',
                    style: TextStyle(color: colors.inkSoft, fontSize: 13),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: colors.terracotta,
                    ),
                  ),
                  TextSpan(
                    text: ' en el barrio',
                    style: TextStyle(color: colors.inkSoft, fontSize: 13),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: colors.inkSoft),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    await ref.read(autenticacionProvider.notifier).cerrarSesion();
    if (context.mounted) {
      context.go(RutasApp.iniciarSesion);
    }
  }
}
