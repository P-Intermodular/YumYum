import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/location/formato_distancia.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../producto/domain/entities/producto_model.dart';

/// Card destacada para el primer plato del feed.
///
/// Replica figma (`screens-a.tsx#L137-L174`): imagen 176 con gradient,
/// badge "Recién hecho" arriba a la izquierda, favorito arriba a la derecha,
/// avatar+cocinero+rating overlay abajo, footer con título/precio/distancia.
class HeroPlato extends StatelessWidget {
  final ProductoModel producto;

  const HeroPlato({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final esIntercambio = producto.tipo == TipoOferta.intercambio;
    final precioTexto = esIntercambio || producto.precio == null
        ? 'Intercambio'
        : '${producto.precio!.toStringAsFixed(2)} €';
    final hora = DateFormat('HH:mm').format(producto.creadoEn);
    final distancia = producto.distanciaKm != null
        ? formatearDistanciaKm(producto.distanciaKm!)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push(RutasApp.productoDetalle(producto.id)),
          child: Container(
            decoration: BoxDecoration(
              color: colors.paper,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colors.ink.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                  spreadRadius: -12,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImagenConOverlays(context, colors, hora),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              producto.titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontSize: 18,
                                    height: 1.25,
                                    color: colors.ink,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                precioTexto,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: 18,
                                      height: 1.1,
                                      color: colors.terracottaDeep,
                                    ),
                              ),
                              if (!esIntercambio && producto.precio != null)
                                Text(
                                  '/ ración',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.inkSoft,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: colors.inkSoft),
                          const SizedBox(width: 4),
                          Text(
                            distancia ?? 'Cerca de ti',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.inkSoft,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time_outlined,
                              size: 12, color: colors.inkSoft),
                          const SizedBox(width: 4),
                          Text(
                            hora,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.inkSoft,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _textoRaciones(producto),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.oliveDeep,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (producto.etiquetas.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final etq in producto.etiquetas)
                              _PillEtiqueta(label: etq, colors: colors),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _textoRaciones(ProductoModel producto) {
    final disp = producto.racionesDisponibles;
    final total = producto.racionesTotales;
    if (total <= 1) {
      return total == 1 ? '1 ración' : 'Sin stock';
    }
    if (disp == total) {
      return '$total raciones';
    }
    return '$disp de $total raciones';
  }

  Widget _buildImagenConOverlays(
    BuildContext context,
    YumColors colors,
    String hora,
  ) {
    return SizedBox(
      height: 176,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            producto.urlImagen,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: colors.cream2),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.paper.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: colors.mustard),
                  const SizedBox(width: 4),
                  Text(
                    'Recién hecho',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.paper.withValues(alpha: 0.92),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.favorite_border_rounded,
                size: 18,
                color: colors.terracotta,
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: InkWell(
              onTap: () => context.push(
                RutasApp.perfilUsuario(producto.propietario.id),
              ),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AvatarUsuario(
                    nombre: producto.propietario.nombre,
                    identificadorColor: producto.propietario.id,
                    urlImagen: producto.propietario.urlImagenPerfil,
                    radius: 14,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        producto.propietario.nombre,
                        style: TextStyle(
                          color: colors.paper,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: colors.mustard,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            producto.propietario.numeroValoraciones == 0
                                ? 'Nuevo'
                                : producto.propietario.valoracionMedia
                                    .toStringAsFixed(1),
                            style: TextStyle(
                              color: colors.paper.withValues(alpha: 0.95),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill compacta para mostrar una etiqueta dietética en el feed.
class _PillEtiqueta extends StatelessWidget {
  final String label;
  final YumColors colors;

  const _PillEtiqueta({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.cream2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.inkSoft,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
