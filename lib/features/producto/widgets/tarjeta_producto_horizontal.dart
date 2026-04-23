import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../domain/entities/producto_model.dart';

class TarjetaProductoHorizontal extends StatelessWidget {
  final ProductoModel producto;

  const TarjetaProductoHorizontal({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(RutasApp.productoDetalle(producto.id)),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              producto.urlImagen,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 120, color: Colors.grey.shade200),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F4A5B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    producto.tipo == TipoOferta.intercambio
                        ? 'Intercambio'
                        : '${producto.precio?.toStringAsFixed(2)} EUR',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
