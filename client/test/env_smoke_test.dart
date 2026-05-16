import 'package:flutter_test/flutter_test.dart';
import 'package:vibecall/app/env.dart';

void main() {
  group('Env (smoke)', () {
    test('SUPABASE_URL is non-empty (passed via --dart-define-from-file)', () {
      expect(Env.supabaseUrl, isNotEmpty);
      expect(Env.supabaseUrl, startsWith('https://'));
      expect(Env.supabaseUrl, contains('.supabase.co'));
    });

    test('SUPABASE_ANON_KEY is non-empty', () {
      expect(Env.supabaseAnonKey, isNotEmpty);
    });

    test('assertAll() does not throw', () {
      expect(Env.assertAll, returnsNormally);
    });

    test('env defaults to dev when unset, or is explicit value', () {
      expect(Env.env, isNotEmpty);
    });
  });
}
