import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../data/repositories/supabase_pedido_unificado_repository.dart';
import '../domain/repositories/pedido_unificado_repository.dart';

/// Inyecta la implementación de [PedidoUnificadoRepository] respaldada por
/// Supabase.
final pedidoUnificadoRepositoryProvider =
    Provider<PedidoUnificadoRepository>((ref) {
  return SupabasePedidoUnificadoRepository(
    ref.watch(supabaseClientProvider),
  );
});
