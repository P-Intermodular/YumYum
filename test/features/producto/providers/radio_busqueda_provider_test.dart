import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:yumyum/core/location/ubicacion_actual.dart';
import 'package:yumyum/core/location/ubicacion_actual_provider.dart';
import 'package:yumyum/features/producto/domain/entities/producto_model.dart';
import 'package:yumyum/features/producto/domain/repositories/producto_repository.dart';
import 'package:yumyum/features/producto/providers/producto_providers.dart';
import 'package:yumyum/features/producto/providers/producto_repository_provider.dart';

void main() {
  group('radioBusquedaProvider', () {
    test('actualiza el radio y productosCercanosProvider usa el nuevo valor',
        () async {
      final repository = _ProductoRepositoryFake();
      final container = ProviderContainer(
        overrides: [
          ubicacionActualProvider.overrideWith(
            (ref) => const UbicacionActual(
              latitud: 40.4168,
              longitud: -3.7038,
            ),
          ),
          productoRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        productosCercanosProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);

      await container.read(productosCercanosProvider.future);
      expect(repository.ultimoRadioKm, 10);

      container.read(radioBusquedaProvider.notifier).seleccionar(25);
      await container.pump();

      await container.read(productosCercanosProvider.future);
      expect(container.read(radioBusquedaProvider), 25);
      expect(repository.ultimoRadioKm, 25);
    });
  });
}

class _ProductoRepositoryFake implements ProductoRepository {
  double? ultimoRadioKm;

  @override
  Future<List<ProductoModel>> obtenerProductos() async => [];

  @override
  Future<List<ProductoModel>> obtenerProductosCercanos({
    required double latitud,
    required double longitud,
    double radioKm = 10,
    int limite = 50,
  }) async {
    ultimoRadioKm = radioKm;
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
    return producto;
  }

  @override
  Future<LatLng?> obtenerUbicacionExactaProducto(String productoId) async {
    return null;
  }
}
