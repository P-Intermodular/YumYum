import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:yumyum/core/constants/categorias_producto.dart';
import 'package:yumyum/core/constants/estados_app.dart';
import 'package:yumyum/core/supabase/supabase_client_provider.dart';
import 'package:yumyum/features/auth/controllers/auth_controller.dart';
import 'package:yumyum/features/auth/providers/auth_repository_provider.dart';
import 'package:yumyum/features/producto/controllers/datos_publicacion_producto.dart';
import 'package:yumyum/features/producto/controllers/publicar_producto_controller.dart';
import 'package:yumyum/features/producto/domain/entities/producto_model.dart';
import 'package:yumyum/features/producto/domain/repositories/producto_repository.dart';
import 'package:yumyum/features/producto/providers/producto_repository_provider.dart';

import '../../../helpers/auth_test_utils.dart';

void main() {
  group('PublicarProductoController', () {
    test('crea producto con usuario actual y ubicacion publica aproximada',
        () async {
      final repository = _ProductoRepositoryFake();
      final container = ProviderContainer(
        overrides: [
          autenticacionRepositoryProvider.overrideWithValue(
            AuthRepositoryFake(usuarioActual: usuarioTest()),
          ),
          supabaseClientProvider.overrideWithValue(supabaseTestClient()),
          productoRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      container.read(autenticacionProvider);
      await container.pump();

      const exacta = LatLng(40.4168, -3.7038);
      await container
          .read(publicarProductoControllerProvider.notifier)
          .publicar(
            const DatosPublicacionProducto(
              titulo: 'Tarta',
              descripcion: 'Casera',
              tipo: TipoOferta.venta,
              precio: 12,
              categoria: CategoriaProducto.postresDulces,
              sinAlergenosDeclarados: true,
              extensionImagen: 'jpg',
              ubicacionExacta: exacta,
            ),
          );

      final producto = repository.productoCreado!;
      final distancia = const Distance().as(
        LengthUnit.Meter,
        exacta,
        producto.ubicacionPublica,
      );

      expect(producto.titulo, 'Tarta');
      expect(producto.propietario.id, 'usuario-1');
      expect(producto.precio, 12);
      expect(repository.ubicacionExacta, exacta);
      expect(distancia, inInclusiveRange(90, 230));
      expect(
          container.read(publicarProductoControllerProvider).hasError, false);
    });
  });
}

class _ProductoRepositoryFake implements ProductoRepository {
  ProductoModel? productoCreado;
  LatLng? ubicacionExacta;

  @override
  Future<List<ProductoModel>> obtenerProductos() async => [];

  @override
  Future<List<ProductoModel>> obtenerProductosCercanos({
    required double latitud,
    required double longitud,
    double radioKm = 10,
    int limite = 50,
  }) async {
    return [];
  }

  @override
  Future<ProductoModel?> obtenerProductoPorId(String productoId) async => null;

  @override
  Future<List<ProductoModel>> obtenerMisProductosDisponibles(
    String propietarioId,
  ) async {
    return [];
  }

  @override
  Future<ProductoModel> crearProducto(
    ProductoModel producto, {
    required LatLng ubicacionExacta,
    Uint8List? bytesImagen,
    String extensionImagen = 'jpg',
  }) async {
    productoCreado = producto;
    this.ubicacionExacta = ubicacionExacta;
    return producto;
  }

  @override
  Future<LatLng?> obtenerUbicacionExactaProducto(String productoId) async {
    return null;
  }
}
