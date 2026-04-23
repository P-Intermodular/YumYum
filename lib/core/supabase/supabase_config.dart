/// Lee la configuración de Supabase desde variables de compilación.
///
/// Este enfoque evita acoplar la URL y la anon key al código fuente.
class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Indica si la app puede arrancar conectada a Supabase.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
