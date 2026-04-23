import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../data/repositories/supabase_producto_repository.dart';
import '../domain/repositories/producto_repository.dart';

final productoRepositoryProvider = Provider<ProductoRepository>((ref) {
  return SupabaseProductoRepository(ref.watch(supabaseClientProvider));
});
