import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:yumyum/core/location/ubicacion_actual.dart';
import 'package:yumyum/core/location/ubicacion_actual_provider.dart';
import 'package:yumyum/core/supabase/supabase_client_provider.dart';
import 'package:yumyum/features/auth/controllers/auth_controller.dart';
import 'package:yumyum/features/auth/providers/auth_repository_provider.dart';
import 'package:yumyum/features/producto/controllers/datos_publicacion_producto.dart';
import 'package:yumyum/features/producto/domain/entities/producto_model.dart';
import 'package:yumyum/features/producto/domain/repositories/producto_repository.dart';
import 'package:yumyum/features/producto/providers/producto_providers.dart';
import 'package:yumyum/features/producto/providers/producto_repository_provider.dart';

import '../../../helpers/auth_test_utils.dart';

void main() {
  group('radioBusquedaProvider', () {
    test(
        'por defecto pide "Todas las distancias" y al seleccionar un radio se '
        'propaga al productosCercanosProvider', () async {
      final repository = _ProductoRepositoryFake();
      final container = ProviderContainer(
        overrides: [
          // productosCercanosProvider espera a que autenticacionProvider salga
          // de loading antes de pedir datos. Inyectamos un fake para que
          // `_esperarSesionLista` continúe sin tocar Supabase real.
          autenticacionRepositoryProvider.overrideWithValue(
            AuthRepositoryFake(usuarioActual: usuarioTest()),
          ),
          supabaseClientProvider.overrideWithValue(supabaseTestClient()),
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

      // Espera a que autenticacionProvider resuelva su valor inicial.
      container.read(autenticacionProvider);
      await container.pump();

      final subscription = container.listen(
        productosCercanosProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);

      // Default null -> "Todas". El provider llama a la RPC con un radio muy
      // amplio y un limite mas grande para no quedarse corto.
      expect(container.read(radioBusquedaProvider), isNull);
      await container.read(productosCercanosProvider.future);
      expect(repository.ultimoRadioKm, greaterThanOrEqualTo(900));
      expect(repository.ultimoLimite, greaterThan(50));

      container.read(radioBusquedaProvider.notifier).seleccionar(25);
      await container.pump();

      await container.read(productosCercanosProvider.future);
      expect(container.read(radioBusquedaProvider), 25);
      expect(repository.ultimoRadioKm, 25);
      expect(repository.ultimoLimite, 50);

      // Volver a "Todas" funciona igual que el default.
      container.read(radioBusquedaProvider.notifier).seleccionar(null);
      await container.pump();
      await container.read(productosCercanosProvider.future);
      expect(repository.ultimoRadioKm, greaterThanOrEqualTo(900));
    });
  });
}

class _ProductoRepositoryFake implements ProductoRepository {
  double? ultimoRadioKm;
  int? ultimoLimite;

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
    ultimoLimite = limite;
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
    List<ImagenSeleccionada> imagenes = const [],
  }) async {
    return producto;
  }

  @override
  Future<LatLng?> obtenerUbicacionExactaProducto(String productoId) async {
    return null;
  }

  @override
  Future<List<ImagenSeleccionada>> obtenerImagenesProducto(
    String productoId,
  ) async {
    return const [];
  }

  @override
  Future<void> actualizarProducto({
    required String productoId,
    required ProductoModel producto,
    required List<ImagenSeleccionada> imagenesFinales,
    required List<String> idsImagenesAEliminar,
  }) async {}

  @override
  Future<bool> eliminarProducto(String productoId) async => true;
}
