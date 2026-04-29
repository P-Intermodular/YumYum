import 'package:flutter_test/flutter_test.dart';
import 'package:yumyum/features/pedidos/data/dtos/transaccion_dto.dart';

void main() {
  group('TransaccionDto', () {
    test('usa un select base sin relaciones embebidas', () {
      expect(
        TransaccionDto.selectBasico,
        contains('comprador_id'),
      );
      expect(
        TransaccionDto.selectBasico,
        contains('vendedor_id'),
      );
      expect(TransaccionDto.selectBasico, isNot(contains('perfiles!')));
      expect(TransaccionDto.selectBasico, isNot(contains('productos!')));
    });

    test('mapea producto y contraparte resueltos por consultas separadas', () {
      final transaccion = TransaccionDto.desdeSupabase(
        {
          'id': 'transaccion-1',
          'tipo': 'intercambio',
          'estado': 'aceptada',
          'producto_id': 'producto-1',
          'producto_ofrecido_id': 'producto-2',
          'comprador_id': 'usuario-1',
          'vendedor_id': 'usuario-2',
          'total': null,
          'creado_en': '2026-04-29T10:00:00Z',
          'completado_en': null,
        },
        'usuario-1',
        producto: {'id': 'producto-1', 'titulo': 'Brownie'},
        contraparte: {
          'id': 'usuario-2',
          'nombre': 'Ana',
          'url_avatar': 'avatar.png',
          'valoracion_media': 4.5,
          'numero_valoraciones': 3,
        },
      );

      expect(transaccion.tituloProducto, 'Brownie');
      expect(transaccion.nombreContraparte, 'Ana');
      expect(transaccion.urlAvatarContraparte, 'avatar.png');
      expect(transaccion.valoracionMediaContraparte, 4.5);
      expect(transaccion.numeroValoracionesContraparte, 3);
    });
  });
}
