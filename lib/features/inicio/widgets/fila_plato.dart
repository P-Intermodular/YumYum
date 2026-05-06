import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/location/formato_distancia.dart';
import '../../../core/theme/yum_colors.dart';
import '../../producto/domain/entities/producto_model.dart';

/// Fila compacta de plato para la sección "Recomendados".
///
/// Replica figma `DishRow` (`screens-a.tsx#L176-L200`): imagen 96, columna
/// con título, precio, cocinero · distancia, rating y una chip con el tipo
/// de oferta.
class FilaPlato extends StatelessWidget {
  final ProductoModel producto;

  const FilaPlato({super.key, required this.producto});

  String _textoRacionesCompacto(ProductoModel p) {
    final d = p.racionesDisponibles;
    final t = p.racionesTotales;
    if (t <= 1) return t == 1 ? '1 ración' : 'Sin stock';
    if (d == t) return '$t raciones';
    return '$d/$t raciones';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final esIntercambio = producto.tipo == TipoOferta.intercambio;
    final precioTexto = esIntercambio || producto.precio == null
        ? 'Intercambio'
        : '${producto.precio!.toStringAsFixed(2)} €';
    final distancia = producto.distanciaKm != null
        ? formatearDistanciaKm(producto.distanciaKm!)
        : 'Cerca';
    final propietario = producto.propietario;
    final tieneRating = propietario.numeroValoraciones > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(RutasApp.productoDetalle(producto.id)),
          child: Container(
            decoration: BoxDecoration(
              color: colors.paper,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: Image.network(
                      producto.urlImagen,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: colors.cream2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                producto.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: colors.ink,
                                      fontSize: 16,
                                      height: 1.2,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              precioTexto,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: colors.terracottaDeep,
                                    fontSize: 16,
                                    height: 1.2,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: () => context.push(
                            RutasApp.perfilUsuario(propietario.id),
                          ),
                          child: Text(
                            'por ${propietario.nombre} · $distancia',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.inkSoft,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: colors.mustard,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              tieneRating
                                  ? '${propietario.valoracionMedia.toStringAsFixed(1)} · ${propietario.numeroValoraciones}'
                                  : 'Sin reseñas',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.inkSoft,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.olive.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _textoRacionesCompacto(producto),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.oliveDeep,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.cream2,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                esIntercambio ? 'Intercambio' : 'Venta',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.inkSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            for (final etq in producto.etiquetas.take(2)) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.olive.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    etq,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.oliveDeep,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
