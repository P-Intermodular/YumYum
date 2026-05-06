import 'package:flutter/material.dart';
import '../../theme/yum_colors.dart';

class DishCardItem extends StatelessWidget {
  final String title;
  final String cookName;
  final String imageUrl;
  final String cookAvatarUrl;
  final double price;
  final double valoracion;
  final int numeroValoraciones;
  final String distance;
  final String time;
  final int portions;
  final VoidCallback? onTap;
  final VoidCallback? onCookTap;
  /// Estado del corazon de favoritos. Null oculta el icono por completo
  /// (para callers que no quieran exponer favoritos en este card).
  final bool? esFavorito;
  final VoidCallback? onToggleFavorito;

  const DishCardItem({
    super.key,
    required this.title,
    required this.cookName,
    required this.imageUrl,
    required this.cookAvatarUrl,
    required this.price,
    required this.valoracion,
    required this.numeroValoraciones,
    required this.distance,
    required this.time,
    required this.portions,
    this.onTap,
    this.onCookTap,
    this.esFavorito,
    this.onToggleFavorito,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: -16,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Image Area
            SizedBox(
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: colors.cream2),
                  ),
                  // Gradient Overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5],
                      ),
                    ),
                  ),
                  // Top Left Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.paper.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 12, color: colors.mustard),
                          const SizedBox(width: 4),
                          Text(
                            'Recién hecho',
                            style: TextStyle(fontSize: 11, color: colors.ink, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Top Right Favorite
                  if (esFavorito != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onToggleFavorito,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.paper.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              esFavorito!
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: colors.terracotta,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Bottom Left Avatar & Info
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onCookTap,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(cookAvatarUrl),
                            backgroundColor: colors.cream2,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cookName,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 10, color: colors.mustard),
                                  const SizedBox(width: 2),
                                  Text(
                                    numeroValoraciones == 0
                                        ? 'Nuevo'
                                        : valoracion.toStringAsFixed(1),
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
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
            ),
            // Bottom Info Area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${price.toStringAsFixed(2)} €',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 18,
                                  color: colors.terracottaDeep,
                                ),
                          ),
                          Text(
                            '/ ración',
                            style: TextStyle(fontSize: 11, color: colors.inkSoft),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: colors.inkSoft),
                      const SizedBox(width: 4),
                      Text(distance, style: TextStyle(fontSize: 12, color: colors.inkSoft)),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: colors.inkSoft),
                      const SizedBox(width: 4),
                      Text(time, style: TextStyle(fontSize: 12, color: colors.inkSoft)),
                      const SizedBox(width: 12),
                      Text(
                        '$portions raciones',
                        style: TextStyle(fontSize: 12, color: colors.oliveDeep, fontWeight: FontWeight.w500),
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
