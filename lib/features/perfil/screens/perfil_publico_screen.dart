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
import '../domain/entities/perfil_publico.dart';
import '../providers/perfil_providers.dart';
import '../widgets/cabecera_perfil.dart';

/// Ficha pública del perfil de otro usuario.
///
/// Solo expone los campos públicos (RPC `obtener_perfil_publico`) y permite
/// ver sus platos disponibles y reseñas. Sin información sensible.
class PerfilPublicoScreen extends ConsumerStatefulWidget {
  final String usuarioId;

  const PerfilPublicoScreen({super.key, required this.usuarioId});

  @override
  ConsumerState<PerfilPublicoScreen> createState() =>
      _PerfilPublicoScreenState();
}

class _PerfilPublicoScreenState extends ConsumerState<PerfilPublicoScreen> {
  _TabPublico _tab = _TabPublico.platos;
  final GlobalKey _tabsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilPublicoProvider(widget.usuarioId));
    final colors = context.yumColors;

    return Scaffold(
      body: YumBackground(
        child: perfilAsync.when(
          data: _buildContenido,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildErrorEstado(context, e, colors),
        ),
      ),
    );
  }

  Widget _buildContenido(PerfilPublico perfil) {
    final productosAsync =
        ref.watch(productosDeUsuarioProvider(widget.usuarioId));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CabeceraPerfil(
            usuarioId: perfil.id,
            nombre: perfil.nombre,
            urlImagen: perfil.urlAvatar,
            ciudad: perfil.ciudad,
            bio: perfil.bio,
            creadoEn: perfil.creadoEn,
            // No mostramos badge en perfil ajeno: es_moderador no es público.
            esModerador: null,
            leadingCoverAction: CoverActionBoton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Atrás',
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RutasApp.inicio);
                }
              },
            ),
            coverAction: CoverActionBoton(
              icon: Icons.flag_outlined,
              tooltip: 'Reportar perfil',
              onTap: () => _mostrarReportePendiente(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricas(perfil, productosAsync),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: YumButton(
                        text: 'Ver platos',
                        fullWidth: true,
                        icon: const Icon(Icons.restaurant_menu_outlined),
                        onPressed: () => _verPlatos(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: YumButton(
                        text: 'Mensaje',
                        fullWidth: true,
                        variant: YumButtonVariant.ghost,
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        onPressed: () => _onMensaje(perfil),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(key: _tabsKey, child: _buildTabs(context)),
                const SizedBox(height: 18),
                _buildContenidoTab(perfil, productosAsync),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricas(
    PerfilPublico perfil,
    AsyncValue productosAsync,
  ) {
    final platos = productosAsync.when(
      data: (lista) => lista.length,
      loading: () => null,
      error: (_, __) => 0,
    );
    final cargando = productosAsync.isLoading;

    return Row(
      children: [
        _buildMetrica(
          valor: perfil.numeroValoraciones == 0
              ? '—'
              : perfil.valoracionMedia
                  .toStringAsFixed(1)
                  .replaceAll('.', ','),
          etiqueta: 'Valoración',
          subContenido: perfil.numeroValoraciones == 0
              ? null
              : _buildEstrellitas(perfil.valoracionMedia),
        ),
        const SizedBox(width: 8),
        _buildMetrica(
          valor: cargando && platos == null ? '…' : (platos ?? 0).toString(),
          etiqueta: 'Platos',
        ),
        const SizedBox(width: 8),
        _buildMetrica(
          valor: perfil.pedidosCompletados.toString(),
          etiqueta: 'Pedidos',
        ),
      ],
    );
  }

  Widget _buildMetrica({
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

  Widget _buildEstrellitas(double valoracion) {
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
        border: Border(bottom: BorderSide(color: context.yumColors.line)),
      ),
      child: Row(
        children: [
          _buildTab(_TabPublico.platos, 'Platos'),
          _buildTab(_TabPublico.valoraciones, 'Valoraciones'),
        ],
      ),
    );
  }

  Widget _buildTab(_TabPublico tab, String label) {
    final colors = context.yumColors;
    final activo = _tab == tab;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = tab),
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

  Widget _buildContenidoTab(
    PerfilPublico perfil,
    AsyncValue productosAsync,
  ) {
    switch (_tab) {
      case _TabPublico.platos:
        return _buildGridProductos(productosAsync);
      case _TabPublico.valoraciones:
        return _buildValoraciones(perfil.id);
    }
  }

  Widget _buildGridProductos(AsyncValue productosAsync) {
    final colors = context.yumColors;

    return productosAsync.when(
      data: (productos) {
        if (productos.isEmpty) {
          return _buildEstadoVacio(
            icono: Icons.restaurant_menu_outlined,
            titulo: 'No tiene platos disponibles',
            texto: 'Vuelve más tarde a ver qué cocina.',
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
                      child: Image.network(
                        producto.urlImagen,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: colors.cream2),
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
      error: (e, _) => _buildEstadoVacio(
        icono: Icons.error_outline,
        titulo: 'No se pudieron cargar los platos',
        texto: mensajeError(e),
      ),
    );
  }

  Widget _buildValoraciones(String usuarioId) {
    final valoracionesAsync =
        ref.watch(valoracionesRecibidasProvider(usuarioId));
    final colors = context.yumColors;

    return valoracionesAsync.when(
      data: (valoraciones) {
        if (valoraciones.isEmpty) {
          return _buildEstadoVacio(
            icono: Icons.star_outline_rounded,
            titulo: 'Sin reseñas todavía',
            texto: 'Cuando reciba reseñas, las verás aquí.',
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
      error: (e, _) => _buildEstadoVacio(
        icono: Icons.error_outline,
        titulo: 'No se pudieron cargar las reseñas',
        texto: mensajeError(e),
      ),
    );
  }

  Widget _buildEstadoVacio({
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
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          Icon(icono, color: colors.olive, size: 34),
          const SizedBox(height: 10),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  color: colors.ink,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.inkSoft, fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorEstado(BuildContext context, Object error, YumColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, color: colors.terracottaDeep, size: 48),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar el perfil',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              mensajeError(error),
              style: TextStyle(color: colors.inkSoft, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            YumButton(
              text: 'Volver',
              variant: YumButtonVariant.ghost,
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(RutasApp.inicio),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verPlatos() async {
    if (_tab != _TabPublico.platos) {
      setState(() => _tab = _TabPublico.platos);
    }
    final ctx = _tabsKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        alignment: 0.0,
      );
    }
  }

  void _onMensaje(PerfilPublico perfil) {
    final usuarioActual = ref.read(autenticacionProvider).value;
    if (usuarioActual?.id == perfil.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este es tu propio perfil.')),
      );
      return;
    }

    // El chat directo entre usuarios aún no existe en la app: las
    // conversaciones se crean al solicitar un plato. Guiamos al usuario.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Para escribirle, abre uno de sus platos y pulsa “Pedir”.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _mostrarReportePendiente(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gracias. La revisión de reportes llegará pronto.'),
      ),
    );
  }
}

enum _TabPublico { platos, valoraciones }
