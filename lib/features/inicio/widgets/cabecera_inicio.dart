import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notificaciones/providers/notificacion_providers.dart';

/// Cabecera personal del feed: ubicación + saludo + atajos a la derecha.
///
/// Replica figma (`screens-a.tsx#L88-L96`) con dos extras: una campana
/// pequeña de notificaciones a la izquierda del avatar, para no perder el
/// único acceso a `/notificaciones` desde el feed.
class CabeceraInicio extends ConsumerWidget {
  final String? ciudad;

  const CabeceraInicio({super.key, this.ciudad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(autenticacionProvider).value;
    final colors = context.yumColors;
    final ciudadVisible = (ciudad?.trim().isNotEmpty == true)
        ? ciudad!.trim()
        : 'Tu barrio';
    final nombre = _primerNombre(usuario?.nombre ?? 'vecino');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: colors.inkSoft,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        ciudadVisible,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.inkSoft,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_saludoSegunHora()}, $nombre',
                  style:
                      Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                            height: 1.2,
                            color: colors.ink,
                          ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const _CampanaNotificaciones(),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.push(RutasApp.perfil),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: usuario == null
                  ? CircleAvatar(
                      radius: 22,
                      backgroundColor: colors.cream2,
                      child: Icon(Icons.person_outline, color: colors.inkSoft),
                    )
                  : AvatarUsuario(
                      nombre: usuario.nombre,
                      identificadorColor: usuario.id,
                      urlImagen: usuario.urlImagenPerfil,
                      radius: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _primerNombre(String nombreCompleto) {
    final partes = nombreCompleto.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return 'vecino';
    return partes.first;
  }

  String _saludoSegunHora() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return 'Buenos días';
    if (hora >= 12 && hora < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

class _CampanaNotificaciones extends ConsumerWidget {
  const _CampanaNotificaciones();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    final noLeidas = ref.watch(contadorNotificacionesNoLeidasProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(RutasApp.notificaciones),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.paper,
          shape: BoxShape.circle,
          border: Border.all(color: colors.line),
        ),
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_none, size: 18, color: colors.ink),
            if (noLeidas > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  decoration: BoxDecoration(
                    color: colors.terracotta,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.cream, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    noLeidas > 99 ? '99+' : '$noLeidas',
                    style: TextStyle(
                      color: colors.paper,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1,
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
