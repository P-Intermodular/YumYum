import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/categorias_producto.dart';
import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/ui/yum_app_bar.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../../../core/widgets/ui/yum_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../domain/entities/producto_model.dart';
import '../providers/producto_providers.dart';
import '../widgets/contacto_bottom_sheet.dart';

/// Pantalla de detalle de una oferta concreta.
class DetalleProductoScreen extends ConsumerWidget {
  final String productoId;

  const DetalleProductoScreen({super.key, required this.productoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productoAsync = ref.watch(productoDetalleProvider(productoId));
    final colors = context.yumColors;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const YumAppBar(
        title: '',
        showBack: true,
      ),
      body: YumBackground(
        child: productoAsync.when(
          data: (producto) {
            if (producto == null) {
              return const Center(child: Text('Producto no encontrado'));
            }

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 10,
                bottom: 100, // Espacio para el boton fijo abajo
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Imagen principal con bordes redondeados tipo carta
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Hero(
                      tag: 'img-${producto.id}',
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: colors.ink.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: CachedNetworkImage(
                            imageUrl: producto.urlImagen,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Titulo y Precio
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                producto.titulo,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: producto.tipo == TipoOferta.intercambio
                                    ? colors.mustard.withValues(alpha: 0.2)
                                    : colors.terracotta.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: producto.tipo == TipoOferta.intercambio
                                      ? colors.mustard.withValues(alpha: 0.5)
                                      : colors.terracotta.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                producto.tipo == TipoOferta.intercambio
                                    ? 'Intercambio'
                                    : '${producto.precio?.toStringAsFixed(2)} €',
                                style: TextStyle(
                                  color: producto.tipo == TipoOferta.intercambio
                                      ? colors.ink
                                      : colors.terracottaDeep,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Ficha del cocinero
                        YumCard(
                          padding: const EdgeInsets.all(16),
                          onTap: () {
                            final usuarioActual =
                                ref.read(autenticacionProvider).value;
                            final ruta = usuarioActual?.id ==
                                    producto.propietario.id
                                ? RutasApp.perfil
                                : RutasApp.perfilUsuario(
                                    producto.propietario.id,
                                  );
                            context.push(ruta);
                          },
                          child: Row(
                            children: [
                              AvatarUsuario(
                                nombre: producto.propietario.nombre,
                                identificadorColor: producto.propietario.id,
                                urlImagen: producto.propietario.urlImagenPerfil,
                                radius: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cocinado por',
                                      style: TextStyle(fontSize: 12, color: colors.inkSoft),
                                    ),
                                    Text(
                                      producto.propietario.nombre,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: colors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: colors.mustard),
                                  const SizedBox(width: 4),
                                  Text(
                                    producto.propietario.numeroValoraciones == 0
                                        ? 'Nuevo'
                                        : producto.propietario.valoracionMedia.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Detalles (Descripcion)
                        Text(
                          'Sobre este plato',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          producto.descripcion,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: colors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SeccionCategoriaYEtiquetas(producto: producto),
                        const SizedBox(height: 16),
                        _SeccionAlergenos(producto: producto),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text(mensajeError(e))),
        ),
      ),
      bottomNavigationBar: productoAsync.maybeWhen(
        data: (producto) {
          if (producto == null) return const SizedBox.shrink();
          final usuario = ref.watch(autenticacionProvider).value;
          final esPropietario = usuario?.id == producto.propietario.id;

          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: colors.cream.withValues(alpha: 0.95),
              border: Border(top: BorderSide(color: colors.line.withValues(alpha: 0.5))),
            ),
            child: YumButton(
              text: esPropietario ? 'Es tu publicación' : 'Contactar y probar',
              fullWidth: true,
              variant: esPropietario ? YumButtonVariant.ghost : YumButtonVariant.primary,
              icon: esPropietario ? null : const Icon(Icons.chat_bubble_outline),
              onPressed: esPropietario ? null : () => _contactar(context, ref, producto),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  /// Inicia el flujo de contacto para venta o intercambio mostrando un
  /// BottomSheet con selectores de cantidad y, si aplica, lista de
  /// productos a ofrecer.
  Future<void> _contactar(
    BuildContext context,
    WidgetRef ref,
    ProductoModel producto,
  ) async {
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

/// Sección "Información de alérgenos" — declaración negativa en el sentido
/// del Anexo II del Reglamento UE 1169/2011.
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
              'El cocinero declara que este plato no contiene alérgenos del Anexo II.',
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
