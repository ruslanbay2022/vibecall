class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const livekitWsUrl = String.fromEnvironment('LIVEKIT_WS_URL');
  static const env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static bool get isProd => env == 'prod';

  static void assertAll() {
    assert(supabaseUrl.isNotEmpty, 'SUPABASE_URL is empty');
    assert(supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY is empty');
  }
}
