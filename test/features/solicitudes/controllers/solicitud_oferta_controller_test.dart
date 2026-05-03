import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumyum/features/solicitudes/controllers/solicitud_oferta_controller.dart';
import 'package:yumyum/features/solicitudes/domain/entities/resultado_aceptacion_solicitud_model.dart';
import 'package:yumyum/features/solicitudes/domain/entities/solicitud_oferta_creada_model.dart';
import 'package:yumyum/features/solicitudes/domain/entities/solicitud_oferta_model.dart';
import 'package:yumyum/features/solicitudes/domain/repositories/solicitud_oferta_repository.dart';
import 'package:yumyum/features/solicitudes/providers/solicitud_oferta_repository_provider.dart';

void main() {
  group('SolicitudOfertaController', () {
    test('acepta una solicitud y vuelve a estado data', () async {
      final repository = _SolicitudOfertaRepositoryFake();
      final container = ProviderContainer(
        overrides: [
          solicitudOfertaRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(solicitudOfertaControllerProvider.notifier)
          .aceptar('solicitud-1');

      expect(repository.solicitudAceptadaId, 'solicitud-1');
      expect(
          container.read(solicitudOfertaControllerProvider).isLoading, false);
      expect(container.read(solicitudOfertaControllerProvider).hasError, false);
    });

    test('deniega una solicitud y vuelve a estado data', () async {
      final repository = _SolicitudOfertaRepositoryFake();
      final container = ProviderContainer(
        overrides: [
          solicitudOfertaRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(solicitudOfertaControllerProvider.notifier)
          .denegar('solicitud-2');

      expect(repository.solicitudDenegadaId, 'solicitud-2');
      expect(
          container.read(solicitudOfertaControllerProvider).isLoading, false);
      expect(container.read(solicitudOfertaControllerProvider).hasError, false);
    });

    test('cancela una solicitud pendiente y vuelve a estado data', () async {
      final repository = _SolicitudOfertaRepositoryFake();
      final container = ProviderContainer(
        overrides: [
          solicitudOfertaRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(solicitudOfertaControllerProvider.notifier)
          .cancelar('solicitud-3');

      expect(repository.solicitudCanceladaId, 'solicitud-3');
      expect(
          container.read(solicitudOfertaControllerProvider).isLoading, false);
      expect(container.read(solicitudOfertaControllerProvider).hasError, false);
    });
  });
}

class _SolicitudOfertaRepositoryFake implements SolicitudOfertaRepository {
  String? solicitudAceptadaId;
  String? solicitudDenegadaId;
  String? solicitudCanceladaId;

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
  Stream<List<SolicitudOfertaModel>> escucharSolicitudesRecibidas(
    String usuarioId,
  ) {
    return Stream.value([]);
  }

  @override
  Stream<List<SolicitudOfertaModel>> escucharSolicitudesEnviadas(
    String usuarioId,
  ) {
    return Stream.value([]);
  }

  @override
  Future<SolicitudOfertaCreadaModel> crearSolicitudOferta({
    required String productoId,
    required String tipoSolicitud,
    String? productoOfrecidoId,
    String? mensaje,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ResultadoAceptacionSolicitudModel> aceptarSolicitudOferta(
    String solicitudId,
  ) async {
    solicitudAceptadaId = solicitudId;
    return const ResultadoAceptacionSolicitudModel(
      transaccionId: 'transaccion-1',
      conversacionId: 'chat-1',
    );
  }

  @override
  Future<void> denegarSolicitudOferta(String solicitudId) async {
    solicitudDenegadaId = solicitudId;
  }

  @override
  Future<void> cancelarSolicitudOferta(String solicitudId) async {
    solicitudCanceladaId = solicitudId;
  }
}

