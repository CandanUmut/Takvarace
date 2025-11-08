import '../../core/env.dart';
import '../../core/utils/week.dart';
import '../../domain/models/user_profile.dart';
import 'supabase_client.dart';

class ScoreRepository {
  ScoreRepository(this._manager);

  final SupabaseManager _manager;

  Future<void> upsertWeeklyScore({required int scoreDelta}) async {
    if (Env.supabaseUrl.isEmpty || Env.supabaseAnonKey.isEmpty) {
      return; // offline mode
    }
    final client = await _manager.init();
    final hasSession = await _manager.ensureAnonSession();
    if (!hasSession) {
      return;
    }
    final weekStart = WeekUtils.weekStart(DateTime.now());
    final weekDate = weekStart.toIso8601String().substring(0, 10);
    await client.from('leaderboard').upsert({
      'user_id': client.auth.currentUser!.id,
      'week_start': weekDate,
      'score': scoreDelta,
    }, onConflict: 'user_id,week_start');
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    if (Env.supabaseUrl.isEmpty || Env.supabaseAnonKey.isEmpty) {
      return [];
    }
    final client = await _manager.init();
    final hasSession = await _manager.ensureAnonSession();
    if (!hasSession) {
      return [];
    }
    final weekStart = WeekUtils.weekStart(DateTime.now());
    final weekDate = weekStart.toIso8601String().substring(0, 10);
    final response = await client
        .from('leaderboard')
        .select('alias:users(alias),score,week_start')
        .eq('week_start', weekDate)
        .order('score', ascending: false)
        .limit(20);
    return (response as List<dynamic>).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<void> ensureUser(UserProfile profile) async {
    if (Env.supabaseUrl.isEmpty || Env.supabaseAnonKey.isEmpty) {
      return;
    }
    final client = await _manager.init();
    final hasSession = await _manager.ensureAnonSession();
    if (!hasSession) {
      return;
    }
    await client.from('users').upsert({
      'id': client.auth.currentUser!.id,
      'alias': profile.alias,
    });
  }
}
