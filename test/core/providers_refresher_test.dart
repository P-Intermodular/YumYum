import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumyum/core/location/ubicacion_actual_provider.dart';
import 'package:yumyum/core/providers_refresher.dart';
import 'package:yumyum/features/chat/domain/entities/conversacion_model.dart';
import 'package:yumyum/features/chat/providers/chat_providers.dart';
import 'package:yumyum/features/pedidos/providers/transaccion_providers.dart';
import 'package:yumyum/features/solicitudes/providers/solicitud_oferta_providers.dart';
import 'package:yumyum/features/perfil/providers/perfil_providers.dart';
import 'package:yumyum/features/producto/domain/entities/producto_model.dart';
import 'package:yumyum/features/producto/providers/producto_providers.dart';
import 'package:yumyum/features/valoraciones/domain/entities/valoracion_model.dart';
import 'package:yumyum/features/valoraciones/providers/valoracion_providers.dart';

void main() {
  group('RefrescarProviders', () {
    test('refresca catalogo completo', () async {
      var productos = 0;
      var cercanos = 0;
      var propios = 0;

      final refrescarProvider = Provider<VoidCallback>((ref) {
        return () => ref.refrescarCatalogo();
      });
      final container = ProviderContainer(
        overrides: [
          productosProvider.overrideWith((ref) async {
            productos++;
            return const <ProductoModel>[];
          }),
          productosCercanosProvider.overrideWith((ref) async {
            cercanos++;
            return const <ProductoModel>[];
          }),
          misProductosProvider.overrideWith((ref) async {
            propios++;
            return const <ProductoModel>[];
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(productosProvider.future);
      await container.read(productosCercanosProvider.future);
      await container.read(misProductosProvider.future);

      expect((productos, cercanos, propios), (1, 1, 1));

      container.read(refrescarProvider)();
      await container.pump();

      await container.read(productosProvider.future);
      await container.read(productosCercanosProvider.future);
      await container.read(misProductosProvider.future);

      expect((productos, cercanos, propios), (2, 2, 2));
    });

    test('refresca pedidos', () async {
      var lecturas = 0;
      final refrescarProvider = Provider<VoidCallback>((ref) {
        return () => ref.refrescarPedidos();
      });
      final container = ProviderContainer(
        overrides: [
          solicitudesRecibidasProvider.overrideWith((ref) {
            lecturas++;
            return Stream.value([]);
          }),
          solicitudesEnviadasProvider.overrideWith((ref) {
            return Stream.value([]);
          }),
          transaccionesListProvider.overrideWith((ref) {
            return Stream.value([]);
          }),
        ],
      );
      addTearDown(container.dispose);

      final sub1 = container.listen(solicitudesRecibidasProvider, (_, __) {});
      final sub2 = container.listen(solicitudesEnviadasProvider, (_, __) {});
      final sub3 = container.listen(transaccionesListProvider, (_, __) {});

      await container.read(solicitudesRecibidasProvider.future);
      expect(lecturas, 1);

      container.read(refrescarProvider)();
      await container.pump();

      await container.read(solicitudesRecibidasProvider.future);
      expect(lecturas, 2);

      sub1.close();
      sub2.close();
      sub3.close();
    });

    test('refresca chats', () async {
      var lecturas = 0;
      final refrescarProvider = Provider<VoidCallback>((ref) {
        return () => ref.refrescarChats();
      });
      final container = ProviderContainer(
        overrides: [
          listaChatsProvider.overrideWith((ref) {
            lecturas++;
            return Stream.value(const <ConversacionModel>[]);
          }),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(listaChatsProvider, (_, __) {});
      await container.read(listaChatsProvider.future);
      expect(lecturas, 1);

      container.read(refrescarProvider)();
      await container.pump();

      await container.read(listaChatsProvider.future);
      expect(lecturas, 2);
      sub.close();
    });

    test('refresca ubicacion actual', () async {
      var lecturas = 0;
      final refrescarProvider = Provider<VoidCallback>((ref) {
        return () => ref.refrescarUbicacionActual();
      });
      final container = ProviderContainer(
        overrides: [
          ubicacionActualProvider.overrideWith((ref) async {
            lecturas++;
            return null;
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(ubicacionActualProvider.future);
      expect(lecturas, 1);

      container.read(refrescarProvider)();
      await container.pump();

      await container.read(ubicacionActualProvider.future);
      expect(lecturas, 2);
    });

    test('refresca valoraciones concretas', () async {
      var valoracionUsuario = 0;
      var valoracionesRecibidas = 0;
      final refrescarProvider = Provider<VoidCallback>((ref) {
        return () {
          ref.refrescarValoracionUsuario(
            transaccionId: 'transaccion-1',
            usuarioId: 'usuario-1',
          );
          ref.refrescarValoracionesRecibidas('usuario-1');
        };
      });
      final container = ProviderContainer(
        overrides: [
          valoracionUsuarioProvider.overrideWith((ref, params) async {
            valoracionUsuario++;
            return null;
          }),
          valoracionesRecibidasProvider.overrideWith((ref, usuarioId) async {
            valoracionesRecibidas++;
            return const <ValoracionModel>[];
          }),
        ],
      );
      addTearDown(container.dispose);

      final usuarioProvider = valoracionUsuarioProvider(
        ('transaccion-1', 'usuario-1'),
      );
      final recibidasProvider = valoracionesRecibidasProvider('usuario-1');

      await container.read(usuarioProvider.future);
      await container.read(recibidasProvider.future);
      expect((valoracionUsuario, valoracionesRecibidas), (1, 1));

      container.read(refrescarProvider)();
      await container.pump();

      await container.read(usuarioProvider.future);
      await container.read(recibidasProvider.future);
      expect((valoracionUsuario, valoracionesRecibidas), (2, 2));
    });
  });
}

typedef VoidCallback = void Function();
