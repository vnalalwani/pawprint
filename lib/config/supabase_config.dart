import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class SupabaseConfig {
  static const projectId = 'mtyouhpigpohzjifhdxz';
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mtyouhpigpohzjifhdxz.supabase.co',
  );
  static const schema = 'treatfeedtails';
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_H-5ERWwnDrEpfSxGwrqTag_TL73MeZI',
  );
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (publishableKey.isEmpty) return;

    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      postgrestOptions: const PostgrestClientOptions(schema: schema),
    );
    _initialized = true;
  }
}
