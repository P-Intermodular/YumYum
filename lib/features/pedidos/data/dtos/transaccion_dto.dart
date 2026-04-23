import '../../../../core/constants/estados_app.dart';
import '../../domain/entities/transaccion_model.dart';

abstract final class TransaccionDto {
  static TransaccionModel desdeSupabase(
    Map<String, dynamic> transaccion,
    String usuarioId,
  ) {
    final producto = transaccion['producto'] as Map<String, dynamic>?;
    final esComprador = transaccion['comprador_id'] == usuarioId;
    final contraparte = transaccion[esComprador ? 'vendedor' : 'comprador']
        as Map<String, dynamic>?;

    return TransaccionModel(
      id: transaccion['id'] as String,
      tipo: transaccion['tipo'] as String? ?? TipoOferta.venta,
      estado: transaccion['estado'] as String? ?? EstadoTransaccion.aceptada,
      tituloProducto: producto?['titulo'] as String? ?? 'Oferta YumYum',
      nombreContraparte: contraparte?['nombre'] as String? ?? 'Usuario YumYum',
      total: _toDoubleOrNull(transaccion['total']),
      creadoEn: DateTime.tryParse(transaccion['creado_en']?.toString() ?? '') ??
          DateTime.now(),
      completadoEn:
          DateTime.tryParse(transaccion['completado_en']?.toString() ?? ''),
    );
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
