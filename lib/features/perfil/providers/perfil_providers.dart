import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../producto/domain/entities/producto_model.dart';
import '../../producto/providers/producto_repository_provider.dart';

final misProductosProvider = FutureProvider<List<ProductoModel>>((ref) async {
  final usuario = ref.watch(autenticacionProvider).value;
  if (usuario == null) return [];

  return ref
      .watch(productoRepositoryProvider)
      .obtenerMisProductosDisponibles(usuario.id);
});
