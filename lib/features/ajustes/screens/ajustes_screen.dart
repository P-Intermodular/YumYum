import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/ui/yum_app_bar.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/domain/entities/usuario_model.dart';
import '../widgets/ajustes_grupo.dart';
import '../widgets/ajustes_tile.dart';

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
                  onTap: () => context.push(RutasApp.notificaciones),
                ),
                AjustesTile(
                  icon: Icons.location_on_outlined,
                  label: 'Ubicación',
                  hint: _hintUbicacion(usuario),
                  onTap: () => context.push(RutasApp.perfilUbicacion),
                  ultimo: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AjustesGrupo(
              titulo: 'Preferencias',
              children: [
                AjustesTile(
                  icon: Icons.eco_outlined,
                  label: 'Dieta',
                  hint: _hintPreferencias(usuario.preferencias),
                  onTap: () => context.push(RutasApp.perfilEditar),
                ),
                AjustesTile(
                  icon: Icons.verified_user_outlined,
                  label: 'Certificación sanitaria',
                  hint: _hintCertificacion(usuario.certificacionSanitaria),
                  onTap: () => context.push(RutasApp.perfilEditar),
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

  String _hintPreferencias(List<String> preferencias) {
    if (preferencias.isEmpty) return 'Sin indicar';
    if (preferencias.length == 1) return preferencias.first;
    return '${preferencias.length} seleccionadas';
  }

  String _hintCertificacion(String? certificacion) {
    final valor = certificacion?.trim();
    if (valor == null || valor.isEmpty) return 'No indicada';
    return 'Indicada';
  }

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    await ref.read(autenticacionProvider.notifier).cerrarSesion();
    if (context.mounted) {
      context.go(RutasApp.iniciarSesion);
    }
  }
}
