import 'package:flutter/material.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/format/tiempo_relativo.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../producto/domain/entities/producto_model.dart';

/// Tarjeta compacta para el grid de la pantalla "Guardados".
///
/// Replica el lenguaje visual del prototipo Figma (`screens-b.tsx#L484-L547`):
/// imagen 4:5, badge de precio o intercambio arriba a la izquierda, corazón
/// flotante arriba a la derecha que destoca el favorito, overlay inferior con
/// avatar+nombre del cocinero y rating, y un footer con título + tiempo
/// relativo desde el guardado.
class TarjetaPlatoGuardado extends StatelessWidget {
  final ProductoModel producto;
  final DateTime guardadoEn;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorito;

  const TarjetaPlatoGuardado({
    super.key,
    required this.producto,
    required this.guardadoEn,
    required this.onTap,
    required this.onToggleFavorito,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: colors.paper,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.ink.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -14,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Imagen(url: producto.urlImagen, fallback: colors.cream2),
                    _GradienteInferior(),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _BadgePrecio(producto: producto),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _BotonCorazon(onTap: onToggleFavorito),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: _OverlayCocinero(producto: producto),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatearTiempoRelativo(guardadoEn),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Imagen extends StatelessWidget {
  final String url;
  final Color fallback;
  const _Imagen({required this.url, required this.fallback});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return Container(color: fallback);
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: fallback),
    );
  }
}

class _GradienteInferior extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.45),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55],
        ),
      ),
    );
  }
}

class _BadgePrecio extends StatelessWidget {
  final ProductoModel producto;
  const _BadgePrecio({required this.producto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final esIntercambio = producto.tipo == TipoOferta.intercambio;

    if (esIntercambio) {
      return Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: colors.olive,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_outlined, size: 11, color: colors.paper),
            const SizedBox(width: 4),
            Text(
              'Intercambio',
              style: TextStyle(
                fontSize: 10,
                color: colors.paper,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final precio = producto.precio ?? 0;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.paper.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Text(
        '${precio.toStringAsFixed(2).replaceAll('.', ',')} €',
        style: TextStyle(
          fontSize: 11,
          color: colors.terracottaDeep,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BotonCorazon extends StatelessWidget {
  final VoidCallback onTap;
  const _BotonCorazon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.paper.withValues(alpha: 0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.ink.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.favorite_rounded,
            size: 16,
            color: colors.terracotta,
          ),
        ),
      ),
    );
  }
}

class _OverlayCocinero extends StatelessWidget {
  final ProductoModel producto;
  const _OverlayCocinero({required this.producto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final propietario = producto.propietario;
    final tieneValoraciones = propietario.numeroValoraciones > 0;

    return Row(
      children: [
        AvatarUsuario(
          nombre: propietario.nombre,
          identificadorColor: propietario.id,
          urlImagen: propietario.urlImagenPerfil,
          radius: 10,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            propietario.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          height: 18,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 10, color: colors.mustard),
              const SizedBox(width: 2),
              Text(
                tieneValoraciones
                    ? propietario.valoracionMedia
                        .toStringAsFixed(1)
                        .replaceAll('.', ',')
                    : 'Nuevo',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
