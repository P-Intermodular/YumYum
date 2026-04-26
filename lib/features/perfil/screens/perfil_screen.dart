import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../producto/widgets/tarjeta_producto_horizontal.dart';
import '../../valoraciones/providers/valoracion_providers.dart';
import '../providers/perfil_providers.dart';
import '../widgets/insignia_valoracion.dart';

/// Pantalla de perfil del usuario autenticado.
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(autenticacionProvider).value;
    final productosAsync = ref.watch(misProductosProvider);

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: Text('No has iniciado sesion')),
      );
    }

    final topColor = Colors.green.shade200;

    return Scaffold(
      appBar: const YumYumAppBar(
        titulo: 'Perfil',
        mostrarBotonVolver: true,
        mostrarBotonPerfil: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: topColor, width: 3),
              ),
              child: AvatarUsuario(
                nombre: usuario.nombre,
                identificadorColor: usuario.id,
                urlImagen: usuario.urlImagenPerfil,
                radius: 50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              usuario.nombre,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F4A5B),
                  ),
            ),
            const SizedBox(height: 4),
            Text(usuario.correo,
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 16),
            InsigniaValoracion(
              valoracion: usuario.valoracionMedia,
              cantidad: usuario.numeroValoraciones,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: productosAsync.when(
                data: (productos) => Row(
                  children: [
                    _buildCajaEstadistica(
                        productos.length.toString(), 'Platos', topColor),
                    const SizedBox(width: 12),
                    _buildCajaEstadistica(usuario.numeroValoraciones.toString(),
                        'Valoraciones', topColor),
                    const SizedBox(width: 12),
                    _buildCajaEstadistica(
                        usuario.preferencias.length.toString(),
                        'Preferencias',
                        topColor),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text(mensajeError(e)),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildTarjetaInformacion(
                    titulo: 'Ubicacion',
                    contenido: usuario.ubicacionPredeterminada != null
                        ? 'Ubicacion configurada (Toca para editar)'
                        : 'Sin ubicacion configurada — toca para anadir',
                    icon: Icons.location_on_outlined,
                    onTap: () => context.push(RutasApp.perfilUbicacion),
                    colorContenido: usuario.ubicacionPredeterminada == null
                        ? Colors.orange.shade800
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTarjetaInformacion(
                    titulo: 'Certificacion sanitaria',
                    contenido: usuario.certificacionSanitaria ?? 'No indicada',
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildTituloSeccion('Mis platos publicados'),
            const SizedBox(height: 16),
            productosAsync.when(
              data: (productos) {
                if (productos.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child:
                          Text('Todavia no has publicado platos disponibles.'),
                    ),
                  );
                }

                return SizedBox(
                  height: 204,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: productos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) =>
                        TarjetaProductoHorizontal(producto: productos[index]),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(mensajeError(e)),
              ),
            ),
            const SizedBox(height: 32),
            _buildTituloSeccion('Valoraciones recibidas'),
            const SizedBox(height: 16),
            _buildValoracionesRecibidas(ref, usuario.id),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () async {
                await ref.read(autenticacionProvider.notifier).cerrarSesion();
                if (context.mounted) {
                  context.go(RutasApp.iniciarSesion);
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Cerrar sesion',
                  style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Dibuja una estadística resumida del perfil.
  Widget _buildCajaEstadistica(String cantidad, String etiqueta, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              cantidad,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4A5B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              etiqueta,
              style: TextStyle(
                  color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  /// Dibuja una tarjeta simple de información descriptiva del perfil.
  Widget _buildTarjetaInformacion({
    required String titulo,
    required String contenido,
    required IconData icon,
    VoidCallback? onTap,
    Color? colorContenido,
  }) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F4A5B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(contenido,
                        style:
                            TextStyle(color: colorContenido ?? Colors.grey.shade700, fontSize: 15)),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.edit, size: 16, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye un título de sección consistente dentro del perfil.
  Widget _buildTituloSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F4A5B),
          ),
        ),
      ),
    );
  }

  /// Muestra las valoraciones recibidas por el usuario.
  Widget _buildValoracionesRecibidas(WidgetRef ref, String usuarioId) {
    final valoracionesAsync = ref.watch(
      valoracionesRecibidasProvider(usuarioId),
    );

    return valoracionesAsync.when(
      data: (valoraciones) {
        if (valoraciones.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Todavia no has recibido valoraciones.'),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final v in valoraciones) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AvatarUsuario(
                        nombre: v.nombreValorador,
                        identificadorColor: v.valoradorId,
                        urlImagen: v.urlAvatarValorador,
                        radius: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.nombreValorador,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F4A5B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < v.puntuacion
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                            if (v.comentario != null &&
                                v.comentario!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                v.comentario!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(mensajeError(e)),
      ),
    );
  }
}
