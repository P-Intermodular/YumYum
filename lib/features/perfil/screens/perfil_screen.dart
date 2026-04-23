import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../producto/widgets/tarjeta_producto_horizontal.dart';
import '../providers/perfil_providers.dart';
import '../widgets/insignia_valoracion.dart';

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
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(usuario.urlImagenPerfil),
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
                    contenido: usuario.ciudad ?? 'Sin ubicacion configurada',
                    icon: Icons.location_on_outlined,
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

  Widget _buildTarjetaInformacion({
    required String titulo,
    required String contenido,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
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
                        TextStyle(color: Colors.grey.shade700, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
}
