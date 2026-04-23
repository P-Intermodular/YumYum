import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/location/formato_distancia.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../domain/entities/producto_model.dart';

/// Tarjeta vertical usada en el feed principal de productos.
class TarjetaProducto extends StatelessWidget {
  final ProductoModel producto;

  const TarjetaProducto({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RutasApp.productoDetalle(producto.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: producto.urlImagen,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          producto.titulo,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: producto.tipo == TipoOferta.intercambio
                              ? Colors.purple.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          producto.tipo == TipoOferta.intercambio
                              ? 'Intercambio'
                              : '${producto.precio?.toStringAsFixed(2)} EUR',
                          style: TextStyle(
                            color: producto.tipo == TipoOferta.intercambio
                                ? Colors.purple.shade800
                                : Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    producto.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      AvatarUsuario(
                        nombre: producto.propietario.nombre,
                        identificadorColor: producto.propietario.id,
                        urlImagen: producto.propietario.urlImagenPerfil,
                        radius: 12,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          producto.propietario.nombre,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (producto.distanciaKm != null) ...[
                        const SizedBox(width: 8),
                        _ChipDistancia(distanciaKm: producto.distanciaKm!),
                      ],
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM HH:mm').format(producto.creadoEn),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipDistancia extends StatelessWidget {
  final double distanciaKm;

  const _ChipDistancia({required this.distanciaKm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.place, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            formatearDistanciaKm(distanciaKm),
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
