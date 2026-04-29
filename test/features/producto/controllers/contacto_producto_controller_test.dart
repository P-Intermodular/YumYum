import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:yumyum/core/constants/estados_app.dart';
import 'package:yumyum/core/supabase/supabase_client_provider.dart';
import 'package:yumyum/features/auth/controllers/auth_controller.dart';
import 'package:yumyum/features/auth/providers/auth_repository_provider.dart';
import 'package:yumyum/features/producto/controllers/contacto_producto_controller.dart';
import 'package:yumyum/features/producto/domain/entities/producto_model.dart';
import 'package:yumyum/features/producto/domain/repositories/producto_repository.dart';
import 'package:yumyum/features/producto/providers/producto_repository_provider.dart';
import 'package:yumyum/features/solicitudes/domain/entities/resultado_aceptacion_solicitud_model.dart';
import 'package:yumyum/features/solicitudes/domain/entities/solicitud_oferta_creada_model.dart';
import 'package:yumyum/features/solicitudes/domain/entities/solicitud_oferta_model.dart';
import 'package:yumyum/features/solicitudes/domain/repositories/solicitud_oferta_repository.dart';
import 'package:yumyum/features/solicitudes/providers/solicitud_oferta_repository_provider.dart';

import '../../../helpers/auth_test_utils.dart';

void main() {
  group('ContactoProductoController', () {
    test('filtra productos propios de intercambio disponibles', () async {
      final productoRepository = _ProductoRepositoryFake(
        misProductos: [
          _producto(id: 'base', tipo: TipoOferta.intercambio),
          _producto(id: 'intercambio', tipo: TipoOferta.intercambio),
          _producto(id: 'venta', tipo: TipoOferta.venta),
        ],
      );
      final container = _crearContainer(
        productoRepository: productoRepository,
        solicitudRepository: _SolicitudOfertaRepositoryFake(),
      );
      addTearDown(container.dispose);

      container.read(autenticacionProvider);
      await container.pump();

      final productos = await container
          .read(contactoProductoControllerProvider.notifier)
          .obtenerProductosIntercambioDisponibles(
            _producto(id: 'base', tipo: TipoOferta.intercambio),
          );

      expect(productos.map((producto) => producto.id), ['intercambio']);
    });

    test('crea solicitud y devuelve conversacionId', () async {
      final solicitudRepository = _SolicitudOfertaRepositoryFake();
      final container = _crearContainer(
        productoRepository: _ProductoRepositoryFake(),
        solicitudRepository: solicitudRepository,
      );
      addTearDown(container.dispose);

      container.read(autenticacionProvider);
      await container.pump();

      final conversacionId = await container
          .read(contactoProductoControllerProvider.notifier)
          .crearSolicitud(
            producto: _producto(id: 'producto-1', tipo: TipoOferta.venta),
          );

      expect(conversacionId, 'chat-1');
      expect(solicitudRepository.productoId, 'producto-1');
      expect(solicitudRepository.tipoSolicitud, TipoOferta.venta);
      expect(
          container.read(contactoProductoControllerProvider).hasError, false);
    });

    test('mantiene vivo el provider durante una solicitud sin listeners',
        () async {
      final solicitudRepository = _SolicitudOfertaRepositoryFake();
      solicitudRepository.crearSolicitudCompleter =
          Completer<SolicitudOfertaCreadaModel>();
      final container = _crearContainer(
        productoRepository: _ProductoRepositoryFake(),
        solicitudRepository: solicitudRepository,
      );
      addTearDown(container.dispose);

      container.read(autenticacionProvider);
      await container.pump();

      final future = container
          .read(contactoProductoControllerProvider.notifier)
          .crearSolicitud(
            producto: _producto(id: 'producto-1', tipo: TipoOferta.venta),
          );

      await container.pump();

      solicitudRepository.crearSolicitudCompleter!.complete(
        const SolicitudOfertaCreadaModel(
          solicitudId: 'solicitud-async',
          conversacionId: 'chat-async',
        ),
      );

      await expectLater(future, completion('chat-async'));
    });
  });
}

ProviderContainer _crearContainer({
  required _ProductoRepositoryFake productoRepository,
  required _SolicitudOfertaRepositoryFake solicitudRepository,
}) {
  return ProviderContainer(
    overrides: [
      autenticacionRepositoryProvider.overrideWithValue(
        AuthRepositoryFake(usuarioActual: usuarioTest()),
      ),
      supabaseClientProvider.overrideWithValue(supabaseTestClient()),
      productoRepositoryProvider.overrideWithValue(productoRepository),
      solicitudOfertaRepositoryProvider.overrideWithValue(solicitudRepository),
    ],
  );
}

ProductoModel _producto({required String id, required String tipo}) {
  return ProductoModel(
    id: id,
    titulo: 'Producto $id',
    descripcion: 'Descripcion',
    urlImagen: '',
    propietario: usuarioTest(),
    creadoEn: DateTime(2026),
    tipo: tipo,
    ubicacionPublica: const LatLng(40.4168, -3.7038),
  );
}

class _ProductoRepositoryFake implements ProductoRepository {
  final List<ProductoModel> misProductos;

  _ProductoRepositoryFake({this.misProductos = const []});

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
    return misProductos;
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

class _SolicitudOfertaRepositoryFake implements SolicitudOfertaRepository {
  Completer<SolicitudOfertaCreadaModel>? crearSolicitudCompleter;
  String? productoId;
  String? tipoSolicitud;

  @override
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesRecibidas(
    String usuarioId,
  ) async {
    return [];
  }

  @override
  Future<List<SolicitudOfertaModel>> obtenerSolicitudesEnviadas(
    String usuarioId,
  ) async {
    return [];
  }

  @override
  Future<SolicitudOfertaCreadaModel> crearSolicitudOferta({
    required String productoId,
    required String tipoSolicitud,
    String? productoOfrecidoId,
    String? mensaje,
  }) async {
    this.productoId = productoId;
    this.tipoSolicitud = tipoSolicitud;
    if (crearSolicitudCompleter != null) {
      return crearSolicitudCompleter!.future;
    }
    return const SolicitudOfertaCreadaModel(
      solicitudId: 'solicitud-1',
      conversacionId: 'chat-1',
    );
  }

  @override
  Future<ResultadoAceptacionSolicitudModel> aceptarSolicitudOferta(
    String solicitudId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> denegarSolicitudOferta(String solicitudId) {
    throw UnimplementedError();
  }
}
