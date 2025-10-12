import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';

class SupabaseManager {
  static final SupabaseManager _instance = SupabaseManager._internal();

  factory SupabaseManager() => _instance;

  SupabaseManager._internal();

  bool _initialized = false;

  Future<SupabaseClient> init() async {
    if (_initialized) {
      return Supabase.instance.client;
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      debug: false,
    );
    _initialized = true;
    return Supabase.instance.client;
  }

  Future<void> ensureAnonSession() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) {
      await client.auth.signInAnonymously();
    }
  }
}
