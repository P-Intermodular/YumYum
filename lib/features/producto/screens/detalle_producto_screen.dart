import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/categorias_producto.dart';
import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/format/tiempo_relativo.dart';
import '../../../core/location/formato_distancia.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../../../core/widgets/ui/yum_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../favoritos/controllers/favorito_controller.dart';
import '../../favoritos/providers/favorito_providers.dart';
import '../../perfil/providers/perfil_providers.dart';
import '../../valoraciones/domain/entities/valoracion_model.dart';
import '../../valoraciones/providers/valoracion_providers.dart';
import '../controllers/publicar_producto_controller.dart';
import '../domain/entities/producto_model.dart';
import '../providers/producto_providers.dart';
import '../widgets/carrusel_imagenes.dart';
import '../widgets/contacto_bottom_sheet.dart';

/// Pantalla de detalle de una oferta concreta.
///
/// Estructura inspirada en `DishDetailScreen` del prototipo Figma: hero con
/// botón flotante atrás, cabecera con badges, ficha del cocinero con CTA al
/// perfil, descripción, grid de tres stats (distancia / publicado / raciones),
/// categoría + etiquetas, alérgenos, últimas reseñas del cocinero, y un CTA
/// fijo abajo que abre el bottom sheet de contacto.
class DetalleProductoScreen extends ConsumerWidget {
  final String productoId;

  const DetalleProductoScreen({super.key, required this.productoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productoAsync = ref.watch(productoDetalleProvider(productoId));

    return Scaffold(
      body: YumBackground(
        child: productoAsync.when(
          data: (producto) {
            if (producto == null) {
              return const _MensajeCentrado(texto: 'Producto no encontrado');
            }
            return _Contenido(producto: producto);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _MensajeCentrado(texto: mensajeError(e)),
        ),
      ),
      bottomNavigationBar: productoAsync.maybeWhen(
        data: (producto) {
          if (producto == null) return const SizedBox.shrink();
          return _BarraInferior(producto: producto);
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

/// Cuerpo scrollable del detalle.
class _Contenido extends StatelessWidget {
  final ProductoModel producto;

  const _Contenido({required this.producto});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Hero(producto: producto),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BadgesYTitulo(producto: producto),
                const SizedBox(height: 18),
                _ChefCard(producto: producto),
                const SizedBox(height: 22),
                _SeccionDescripcion(producto: producto),
                const SizedBox(height: 18),
                _StatsGrid(producto: producto),
                const SizedBox(height: 22),
                _SeccionCategoriaYEtiquetas(producto: producto),
                const SizedBox(height: 16),
                _SeccionAlergenos(producto: producto),
                const SizedBox(height: 22),
                _SeccionUltimasResenas(propietario: producto.propietario),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Imagen hero a aspect 4:3 con gradient overlay inferior y botones flotantes
/// (atrás + favorito). Sin `YumAppBar`: el lugar de la appbar lo ocupa el
/// botón circular translúcido sobre la imagen.
class _Hero extends ConsumerWidget {
  final ProductoModel producto;

  const _Hero({required this.producto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    final topPadding = MediaQuery.of(context).padding.top;
    final ancho = MediaQuery.of(context).size.width;
    final altoHero = ancho * 3 / 4; // aspect 4:3 fijo
    final esFavorito = ref.watch(esFavoritoProvider(producto.id));
    final usuario = ref.watch(autenticacionProvider).value;
    final autenticado = usuario != null;
    final esPropietario = usuario?.id == producto.propietario.id;

    return SizedBox(
      width: ancho,
      height: altoHero,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          CarruselImagenes(
            urls: producto.urlsImagenes,
            heroTag: 'img-${producto.id}',
          ),
        // Fade del cover al fondo para suavizar el corte con el contenido.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 60,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.cream.withValues(alpha: 0),
                    colors.cream,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Sombrita superior para que el botón atrás quede legible.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: topPadding + 64,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.ink.withValues(alpha: 0.30),
                    colors.ink.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: topPadding + 8,
          left: 12,
          child: _BotonFlotanteCircular(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Atrás',
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(RutasApp.inicio);
              }
            },
          ),
        ),
          Positioned(
            top: topPadding + 8,
            right: 12,
            child: esPropietario
                ? _BotonFlotanteCircular(
                    icon: Icons.more_vert_rounded,
                    tooltip: 'Más opciones',
                    onTap: () =>
                        _mostrarMenuPropietario(context, ref, producto),
                  )
                : _BotonFlotanteCircular(
                    icon: esFavorito
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    tooltip: esFavorito ? 'Quitar de favoritos' : 'Guardar',
                    iconColor: esFavorito ? colors.terracotta : colors.ink,
                    onTap: () => _toggleFavorito(context, ref, autenticado),
                  ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet con las acciones que solo aplican al propietario del plato.
  /// Por ahora solo "Eliminar plato"; queda preparado para crecer
  /// (ej: "Pausar publicación") sin cambiar el patrón de UI.
  Future<void> _mostrarMenuPropietario(
    BuildContext context,
    WidgetRef ref,
    ProductoModel producto,
  ) async {
    final colors = Theme.of(context).extension<YumColors>()!;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: colors.terracottaDeep,
                ),
                title: Text(
                  'Eliminar plato',
                  style: TextStyle(
                    color: colors.terracottaDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmarEliminacion(context, ref, producto);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarEliminacion(
    BuildContext context,
    WidgetRef ref,
    ProductoModel producto,
  ) async {
    final colors = Theme.of(context).extension<YumColors>()!;
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
          'Eliminar plato',
          style: TextStyle(color: colors.ink, fontSize: 18),
        ),
        content: Text(
          'Esta acción no se puede deshacer. Si el plato tiene pedidos en '
          'curso se ocultará del catálogo y se conservará el histórico.',
          style: TextStyle(color: colors.inkSoft, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: colors.inkSoft),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: colors.terracottaDeep),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !context.mounted) return;

    try {
      await ref
          .read(publicarProductoControllerProvider.notifier)
          .eliminar(producto.id);
      if (!context.mounted) return;
      mostrarExito(context, 'Plato eliminado');
      // Tras eliminar, el detalle ya no tiene sentido: salimos.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go(RutasApp.inicio);
      }
    } catch (error) {
      if (context.mounted) mostrarError(context, error);
    }
  }

  Future<void> _toggleFavorito(
    BuildContext context,
    WidgetRef ref,
    bool autenticado,
  ) async {
    if (!autenticado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para guardar favoritos.')),
      );
      return;
    }
    try {
      await ref.read(favoritoControllerProvider.notifier).toggle(producto.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}

class _BotonFlotanteCircular extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? iconColor;

  const _BotonFlotanteCircular({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: colors.paper.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.ink.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: iconColor ?? colors.ink),
          ),
        ),
      ),
    );
  }
}

class _BadgesYTitulo extends StatelessWidget {
  final ProductoModel producto;

  const _BadgesYTitulo({required this.producto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final esIntercambio = producto.tipo == TipoOferta.intercambio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(
              icono: Icons.eco_outlined,
              texto: 'Casero',
              fondo: colors.olive.withValues(alpha: 0.15),
              color: colors.oliveDeep,
            ),
            if (esIntercambio)
              _Chip(
                icono: Icons.swap_horiz_rounded,
                texto: 'Intercambio',
                fondo: colors.mustard.withValues(alpha: 0.20),
                color: colors.ink,
              )
            else
              _Chip(
                icono: Icons.auto_awesome_rounded,
                texto: 'Recién hecho',
                fondo: colors.mustard.withValues(alpha: 0.20),
                color: colors.ink,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          producto.titulo,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                height: 1.15,
                color: colors.ink,
              ),
        ),
        const SizedBox(height: 8),
        _LineaValoracion(
          valoracion: producto.propietario.valoracionMedia,
          numero: producto.propietario.numeroValoraciones,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color fondo;
  final Color color;

  const _Chip({
    required this.icono,
    required this.texto,
    required this.fondo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Línea con 5 estrellas + texto "X,Y (N valoraciones)" o "Nuevo cocinero".
class _LineaValoracion extends StatelessWidget {
  final double valoracion;
  final int numero;

  const _LineaValoracion({required this.valoracion, required this.numero});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    if (numero == 0) {
      return Row(
        children: [
          Icon(Icons.star_outline_rounded, size: 18, color: colors.inkSoft),
          const SizedBox(width: 6),
          Text(
            'Nuevo cocinero',
            style: TextStyle(
              color: colors.inkSoft,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    final etiquetaNumero = numero == 1 ? '1 valoración' : '$numero valoraciones';

    return Row(
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < valoracion.round()
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            size: 16,
            color: colors.mustard,
          ),
        const SizedBox(width: 8),
        Text(
          valoracion.toStringAsFixed(1).replaceAll('.', ','),
          style: TextStyle(
            color: colors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($etiquetaNumero)',
          style: TextStyle(color: colors.inkSoft, fontSize: 13),
        ),
      ],
    );
  }
}

class _ChefCard extends ConsumerWidget {
  final ProductoModel producto;

  const _ChefCard({required this.producto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    final propietario = producto.propietario;
    final productosAsync =
        ref.watch(productosDeUsuarioProvider(propietario.id));
    final usuarioActual = ref.watch(autenticacionProvider).value;
    final esYo = usuarioActual?.id == propietario.id;

    final anyo = propietario.creadoEn?.year;
    final platosTexto = productosAsync.when(
      data: (lista) {
        final n = lista.length;
        return n == 1 ? '1 plato' : '$n platos';
      },
      loading: () => '… platos',
      error: (_, __) => '— platos',
    );
    final subtitulo = anyo != null
        ? 'Cocina desde $anyo · $platosTexto'
        : 'Cocina compartida en YumYum · $platosTexto';

    return YumCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          AvatarUsuario(
            nombre: propietario.nombre,
            identificadorColor: propietario.id,
            urlImagen: propietario.urlImagenPerfil,
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  propietario.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.inkSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          YumButton(
            text: 'Ver perfil',
            variant: YumButtonVariant.ghost,
            onPressed: () {
              if (esYo) {
                context.go(RutasApp.perfil);
              } else {
                context.push(RutasApp.perfilUsuario(propietario.id));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SeccionDescripcion extends StatelessWidget {
  final ProductoModel producto;

  const _SeccionDescripcion({required this.producto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sobre este plato',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 16,
                color: colors.ink,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          producto.descripcion,
          style: TextStyle(
            fontSize: 14,
            height: 1.55,
            color: colors.ink.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final ProductoModel producto;

  const _StatsGrid({required this.producto});

  @override
  Widget build(BuildContext context) {
    final distancia = producto.distanciaKm == null
        ? '—'
        : formatearDistanciaKm(producto.distanciaKm!);
    final publicado = formatearTiempoRelativo(producto.creadoEn);
    final raciones =
        '${producto.racionesDisponibles}/${producto.racionesTotales}';

    return Row(
      children: [
        Expanded(
          child: _Stat(
            icono: Icons.place_outlined,
            etiqueta: 'Distancia',
            valor: distancia,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Stat(
            icono: Icons.access_time_rounded,
            etiqueta: 'Publicado',
            valor: publicado,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Stat(
            icono: Icons.restaurant_outlined,
            etiqueta: 'Raciones',
            valor: raciones,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _Stat({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.cream2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icono, size: 18, color: colors.inkSoft),
          const SizedBox(height: 6),
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 11,
              color: colors.inkSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: colors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección que muestra la categoría del plato y las etiquetas dietéticas
/// declaradas como claims positivos por el cocinero.
class _SeccionCategoriaYEtiquetas extends StatelessWidget {
  final ProductoModel producto;

  const _SeccionCategoriaYEtiquetas({required this.producto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final categoriaLabel = CategoriaProducto.label(producto.categoria);
    final categoriaIcono = CategoriaProducto.icono(producto.categoria);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: colors.cream2,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(categoriaIcono, size: 14, color: colors.inkSoft),
              const SizedBox(width: 6),
              Text(
                categoriaLabel,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        for (final etq in producto.etiquetas)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: colors.olive.withValues(alpha: 0.15),
              border: Border.all(
                color: colors.oliveDeep.withValues(alpha: 0.35),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              etq,
              style: TextStyle(
                color: colors.oliveDeep,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// Sección "Información de alérgenos" — declaración del cocinero sobre los
/// 14 alérgenos exigidos por el Reglamento UE 1169/2011.
class _SeccionAlergenos extends StatelessWidget {
  final ProductoModel producto;

  const _SeccionAlergenos({required this.producto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: colors.terracottaDeep,
              ),
              const SizedBox(width: 8),
              Text(
                'Información de alérgenos',
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (producto.sinAlergenosDeclarados)
            Text(
              'El cocinero declara que este plato no contiene ninguno de '
              'los 14 alérgenos principales.',
              style: TextStyle(
                color: colors.inkSoft,
                fontSize: 13,
                height: 1.4,
              ),
            )
          else if (producto.alergenos.isEmpty)
            Text(
              'No se ha declarado información de alérgenos para este plato.',
              style: TextStyle(
                color: colors.inkSoft,
                fontSize: 13,
                height: 1.4,
              ),
            )
          else ...[
            Text(
              'Contiene:',
              style: TextStyle(
                color: colors.inkSoft,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in producto.alergenos)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.mustard.withValues(alpha: 0.25),
                      border: Border.all(
                        color: colors.mustard.withValues(alpha: 0.6),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      a,
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Últimas reseñas recibidas por el cocinero. Se muestran hasta 3 y un link
/// para ver todas en su perfil. Si todavía no tiene reseñas, no se pinta nada
/// (la línea de valoración del header ya comunica "Nuevo cocinero").
class _SeccionUltimasResenas extends ConsumerWidget {
  final dynamic propietario;

  const _SeccionUltimasResenas({required this.propietario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    final asyncResenas =
        ref.watch(valoracionesRecibidasProvider(propietario.id));

    return asyncResenas.when(
      data: (lista) {
        if (lista.isEmpty) return const SizedBox.shrink();
        final muestras = lista.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Últimas valoraciones',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    color: colors.ink,
                  ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < muestras.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _TarjetaResena(valoracion: muestras[i]),
            ],
            if (lista.length > muestras.length) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () =>
                      context.push(RutasApp.perfilUsuario(propietario.id)),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.terracotta,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Text(
                    'Ver todas en el perfil de ${propietario.nombre}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TarjetaResena extends StatelessWidget {
  final ValoracionModel valoracion;

  const _TarjetaResena({required this.valoracion});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final comentario = valoracion.comentario?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cream2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  valoracion.nombreValorador,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (var i = 0; i < 5; i++)
                Icon(
                  i < valoracion.puntuacion
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 12,
                  color: colors.mustard,
                ),
            ],
          ),
          if (comentario.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '«$comentario»',
              style: TextStyle(
                color: colors.ink.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Barra inferior con el CTA principal: pedir / pedir trueque / propio.
class _BarraInferior extends ConsumerWidget {
  final ProductoModel producto;

  const _BarraInferior({required this.producto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.yumColors;
    final usuario = ref.watch(autenticacionProvider).value;
    final esPropietario = usuario?.id == producto.propietario.id;
    final esIntercambio = producto.tipo == TipoOferta.intercambio;
    final agotado = producto.racionesDisponibles <= 0;

    final String texto;
    final bool habilitado;
    final bool esCtaEditar = esPropietario;
    if (esPropietario) {
      texto = 'Editar plato';
      habilitado = true;
    } else if (agotado) {
      texto = 'Sin raciones disponibles';
      habilitado = false;
    } else {
      texto = esIntercambio ? 'Pedir trueque' : 'Pedir ración';
      habilitado = true;
    }

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colors.cream.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: colors.line.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esIntercambio
                      ? 'Trueque'
                      : '${producto.precio?.toStringAsFixed(2) ?? '--'} €',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        color: colors.terracottaDeep,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  esIntercambio ? 'plato por plato' : 'por ración',
                  style: TextStyle(fontSize: 11, color: colors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            child: YumButton(
              text: texto,
              fullWidth: true,
              variant: habilitado
                  ? YumButtonVariant.primary
                  : YumButtonVariant.ghost,
              icon: !habilitado
                  ? null
                  : Icon(
                      esCtaEditar
                          ? Icons.edit_rounded
                          : Icons.chat_bubble_outline_rounded,
                    ),
              onPressed: !habilitado
                  ? null
                  : esCtaEditar
                      ? () => context.push(RutasApp.editarPlato(producto.id))
                      : () => _contactar(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  /// Inicia el flujo de contacto para venta o intercambio mostrando un
  /// BottomSheet con selectores de cantidad y, si aplica, lista de
  /// productos a ofrecer.
  Future<void> _contactar(BuildContext context, WidgetRef ref) async {
    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) {
      mostrarError(context, Exception('Debes iniciar sesión'));
      return;
    }

    try {
      final conversacionId = await mostrarContactoBottomSheet(
        context,
        producto: producto,
      );

      if (conversacionId != null && context.mounted) {
        context.push(RutasApp.chat(conversacionId));
      }
    } catch (error) {
      if (context.mounted) {
        mostrarError(context, error);
      }
    }
  }
}

class _MensajeCentrado extends StatelessWidget {
  final String texto;

  const _MensajeCentrado({required this.texto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.inkSoft, fontSize: 14),
        ),
      ),
    );
  }
}
