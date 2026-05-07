import '../../../producto/domain/entities/producto_model.dart';

/// Producto que el usuario ha marcado como favorito, junto con la fecha en
/// la que se guardó. Se construye uniendo la tabla `favoritos` (que aporta
/// `creado_en`) con `productos` y se utiliza en la pantalla "Guardados".
class ProductoGuardadoModel {
  final ProductoModel producto;
  final DateTime guardadoEn;

  const ProductoGuardadoModel({
    required this.producto,
    required this.guardadoEn,
  });
}
