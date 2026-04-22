import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/producto_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../producto/repositories/producto_repository.dart';

final misProductosProvider = FutureProvider<List<ProductoModel>>((ref) async {
  final usuario = ref.watch(autenticacionProvider).value;
  if (usuario == null) return [];

  return ref
      .watch(productoRepositoryProvider)
      .obtenerMisProductosDisponibles(usuario.id);
});
