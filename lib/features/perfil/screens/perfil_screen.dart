import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../../../core/widgets/ui/yum_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../valoraciones/providers/valoracion_providers.dart';
import '../providers/perfil_providers.dart';
import '../widgets/cabecera_perfil.dart';

/// Pantalla de perfil del usuario autenticado.
class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  _PerfilTab _tabSeleccionada = _PerfilTab.platos;

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(autenticacionProvider).value;
    final productosAsync = ref.watch(misProductosProvider);
    final colors = context.yumColors;

    if (usuario == null) {
      return Scaffold(
        backgroundColor: colors.paper,
        body: const Center(child: Text('No has iniciado sesión')),
      );
    }

    return Scaffold(
      body: YumBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CabeceraPerfil(
                usuarioId: usuario.id,
                nombre: usuario.nombre,
                urlImagen: usuario.urlImagenPerfil,
                ciudad: usuario.ciudad,
                bio: usuario.bio,
                creadoEn: usuario.creadoEn,
                esModerador: usuario.esModerador,
                coverAction: CoverActionBoton(
                  icon: Icons.settings_outlined,
                  tooltip: 'Ajustes',
                  onTap: () => context.push(RutasApp.ajustes),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricas(
                      context: context,
                      platos: productosAsync.when(
                        data: (productos) => productos.length,
                        loading: () => null,
                        error: (_, __) => 0,
                      ),
                      valoraciones: usuario.numeroValoraciones,
                      valoracionMedia: usuario.valoracionMedia,
                      pedidos: usuario.pedidosCompletados,
                      cargando: productosAsync.isLoading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: YumButton(
                            text: 'Editar perfil',
                            fullWidth: true,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => context.push(RutasApp.perfilEditar),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: YumButton(
                            text: 'Guardados',
                            fullWidth: true,
                            variant: YumButtonVariant.ghost,
                            icon: const Icon(Icons.favorite_border_rounded),
                            onPressed: () => context.push(RutasApp.guardados),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTabs(context),
                    const SizedBox(height: 18),
                    _buildContenidoTab(
                      context: context,
                      usuarioId: usuario.id,
                      productosAsync: productosAsync,
                      ubicacionConfigurada: usuario.ubicacionPredeterminada != null,
                      certificacion: usuario.certificacionSanitaria,
                      preferencias: usuario.preferencias,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricas({
    required BuildContext context,
    required int? platos,
    required int valoraciones,
    required double valoracionMedia,
    required int pedidos,
    required bool cargando,
  }) {
    return Row(
      children: [
        _buildMetrica(
          context: context,
          valor: valoraciones == 0
              ? '—'
              : valoracionMedia.toStringAsFixed(1).replaceAll('.', ','),
          etiqueta: 'Valoración',
          subContenido: valoraciones == 0
              ? null
              : _buildEstrellitas(context, valoracionMedia),
        ),
        const SizedBox(width: 8),
        _buildMetrica(
          context: context,
          valor: cargando && platos == null ? '…' : (platos ?? 0).toString(),
          etiqueta: 'Platos',
        ),
        const SizedBox(width: 8),
        _buildMetrica(
          context: context,
          valor: pedidos.toString(),
          etiqueta: 'Pedidos',
        ),
      ],
    );
  }

  Widget _buildMetrica({
    required BuildContext context,
    required String valor,
    required String etiqueta,
    Widget? subContenido,
  }) {
    final colors = context.yumColors;
    return Expanded(
      child: YumCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            Text(
              valor,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              etiqueta,
              style: TextStyle(
                color: colors.inkSoft,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subContenido != null) ...[
              const SizedBox(height: 4),
              subContenido,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstrellitas(BuildContext context, double valoracion) {
    final colors = context.yumColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final activa = i < valoracion.round();
        return Icon(
          activa ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 10,
          color: activa ? colors.mustard : colors.inkSoft,
        );
      }),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.yumColors.line),
        ),
      ),
      child: Row(
        children: [
          _buildTab(context, _PerfilTab.platos, 'Platos'),
          _buildTab(context, _PerfilTab.valoraciones, 'Valoraciones'),
          _buildTab(context, _PerfilTab.datos, 'Datos'),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, _PerfilTab tab, String label) {
    final colors = context.yumColors;
    final activo = _tabSeleccionada == tab;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabSeleccionada = tab),
        child: Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: activo ? colors.terracotta : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: activo ? colors.ink : colors.inkSoft,
              fontSize: 14,
              fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContenidoTab({
    required BuildContext context,
    required String usuarioId,
    required AsyncValue productosAsync,
    required bool ubicacionConfigurada,
    required String? certificacion,
    required List<String> preferencias,
  }) {
    switch (_tabSeleccionada) {
      case _PerfilTab.platos:
        return _buildGridProductos(context, productosAsync);
      case _PerfilTab.valoraciones:
        return _buildValoracionesRecibidas(ref, usuarioId, context);
      case _PerfilTab.datos:
        return _buildDatosPerfil(
          context: context,
          ubicacionConfigurada: ubicacionConfigurada,
          certificacion: certificacion,
          preferencias: preferencias,
        );
    }
  }

  Widget _buildGridProductos(
    BuildContext context,
    AsyncValue productosAsync,
  ) {
    final colors = context.yumColors;

    return productosAsync.when(
      data: (productos) {
        if (productos.isEmpty) {
          return _buildEstadoVacio(
            context: context,
            icono: Icons.restaurant_menu_outlined,
            titulo: 'Todavía no hay platos',
            texto: 'Cuando publiques comida disponible aparecerá aquí.',
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: productos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, index) {
            final producto = productos[index];
            return InkWell(
              onTap: () => context.push(RutasApp.productoDetalle(producto.id)),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.paper,
                  border: Border.all(color: colors.line),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            producto.urlImagen,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: colors.cream2),
                          ),
                          Positioned(
                            left: 6,
                            bottom: 6,
                            child: Container(
                              height: 20,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: colors.paper.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 10,
                                    color: colors.mustard,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    producto.propietario.valoracionMedia
                                        .toStringAsFixed(1),
                                    style: TextStyle(
                                      color: colors.ink,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            producto.precio == null
                                ? 'Intercambio'
                                : '${producto.precio!.toStringAsFixed(2)} €',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontSize: 13,
                                  color: colors.terracottaDeep,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) => _buildEstadoVacio(
        context: context,
        icono: Icons.error_outline,
        titulo: 'No se pudieron cargar tus platos',
        texto: mensajeError(e),
      ),
    );
  }

  Widget _buildDatosPerfil({
    required BuildContext context,
    required bool ubicacionConfigurada,
    required String? certificacion,
    required List<String> preferencias,
  }) {
    final colors = context.yumColors;

    return Column(
      children: [
        _buildTarjetaInformacion(
          context: context,
          titulo: 'Ubicación',
          contenido: ubicacionConfigurada
              ? 'Ubicación predeterminada configurada'
              : 'Sin ubicación configurada. Toca para añadirla.',
          icon: Icons.location_on_outlined,
          onTap: () => context.push(RutasApp.perfilUbicacion),
          colorContenido: ubicacionConfigurada ? null : colors.terracottaDeep,
        ),
        const SizedBox(height: 10),
        _buildTarjetaInformacion(
          context: context,
          titulo: 'Certificación sanitaria',
          contenido: certificacion == null || certificacion.trim().isEmpty
              ? 'No indicada'
              : certificacion,
          icon: Icons.verified_user_outlined,
        ),
        const SizedBox(height: 10),
        YumCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.spa_outlined, size: 20, color: colors.oliveDeep),
                  const SizedBox(width: 8),
                  Text(
                    'Preferencias',
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (preferencias.isEmpty)
                Text(
                  'Sin preferencias indicadas',
                  style: TextStyle(color: colors.inkSoft, fontSize: 13),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preferencia in preferencias)
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: colors.cream2,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colors.line),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          preferencia,
                          style: TextStyle(
                            color: colors.inkSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaInformacion({
    required BuildContext context,
    required String titulo,
    required String contenido,
    required IconData icon,
    VoidCallback? onTap,
    Color? colorContenido,
  }) {
    final colors = context.yumColors;
    return YumCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: colors.cream2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 21, color: colors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contenido,
                    style: TextStyle(
                      color: colorContenido ?? colors.inkSoft,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 22, color: colors.inkSoft),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoVacio({
    required BuildContext context,
    required IconData icono,
    required String titulo,
    required String texto,
  }) {
    final colors = context.yumColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.line, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(icono, color: colors.olive, size: 34),
          const SizedBox(height: 10),
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  color: colors.ink,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            texto,
            style: TextStyle(color: colors.inkSoft, fontSize: 13, height: 1.35),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildValoracionesRecibidas(
    WidgetRef ref,
    String usuarioId,
    BuildContext context,
  ) {
    final valoracionesAsync = ref.watch(valoracionesRecibidasProvider(usuarioId));
    final colors = context.yumColors;

    return valoracionesAsync.when(
      data: (valoraciones) {
        if (valoraciones.isEmpty) {
          return _buildEstadoVacio(
            context: context,
            icono: Icons.star_outline_rounded,
            titulo: 'Sin valoraciones todavía',
            texto: 'Cuando completes transacciones, las reseñas aparecerán aquí.',
          );
        }

        return Column(
          children: [
            for (final v in valoraciones) ...[
              YumCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvatarUsuario(
                      nombre: v.nombreValorador,
                      identificadorColor: v.valoradorId,
                      urlImagen: v.urlAvatarValorador,
                      radius: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  v.nombreValorador,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: colors.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < v.puntuacion
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 16,
                                    color: colors.mustard,
                                  );
                                }),
                              ),
                            ],
                          ),
                          if (v.comentario != null &&
                              v.comentario!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              v.comentario!,
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.inkSoft,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) => _buildEstadoVacio(
        context: context,
        icono: Icons.error_outline,
        titulo: 'No se pudieron cargar las valoraciones',
        texto: mensajeError(e),
      ),
    );
  }
}

enum _PerfilTab { platos, valoraciones, datos }
