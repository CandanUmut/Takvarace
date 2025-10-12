import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/repo_local.dart';
import '../data/local/secure_store.dart';
import '../data/remote/repo_score.dart';
import '../data/remote/supabase_client.dart';
import '../domain/models/deed.dart';
import '../domain/models/diary_entry.dart';
import '../domain/models/user_profile.dart';
import '../domain/services/parser_service.dart';
import '../domain/services/repentance_service.dart';
import '../domain/services/score_service.dart';
import '../domain/services/streak_service.dart';

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

final localRepositoryProvider = Provider<LocalRepository>((ref) => LocalRepository(ref.watch(secureStoreProvider)));

final supabaseManagerProvider = Provider<SupabaseManager>((ref) => SupabaseManager());

final scoreRepositoryProvider = Provider<ScoreRepository>((ref) => ScoreRepository(ref.watch(supabaseManagerProvider)));

final scoreServiceProvider = Provider<ScoreService>((ref) => ScoreService(
      ref.watch(localRepositoryProvider),
      ref.watch(scoreRepositoryProvider),
    ));

final streakServiceProvider = Provider<StreakService>((ref) => StreakService(ref.watch(localRepositoryProvider)));

final repentanceServiceProvider = Provider<RepentanceService>((ref) => RepentanceService(
      ref.watch(localRepositoryProvider),
      ref.watch(scoreServiceProvider),
      ref.watch(streakServiceProvider),
    ));

class ProfileController extends StateNotifier<AsyncValue<UserProfile?>> {
  ProfileController(this._localRepository, this._scoreService) : super(const AsyncValue.loading()) {
    _load();
  }

  final LocalRepository _localRepository;
  final ScoreService _scoreService;

  Future<void> _load() async {
    try {
      final profile = await _localRepository.loadProfile();
      if (profile != null) {
        await _scoreService.registerProfile(profile);
      }
      state = AsyncValue.data(profile);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _localRepository.saveProfile(profile);
    await _scoreService.registerProfile(profile);
    state = AsyncValue.data(profile);
  }
}

final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<UserProfile?>>((ref) {
  return ProfileController(ref.watch(localRepositoryProvider), ref.watch(scoreServiceProvider));
});

final parserServiceProvider = FutureProvider<ParserService>((ref) async {
  final profile = ref.watch(profileControllerProvider).value;
  final languageCode = profile?.languageCode ?? 'en';
  final pointsConfig = await ref.watch(scoreServiceProvider).loadPointsConfig(languageCode);
  return ParserService(pointsConfig: pointsConfig);
});

final pointsConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final profile = ref.watch(profileControllerProvider).value;
  final languageCode = profile?.languageCode ?? 'en';
  return ref.watch(scoreServiceProvider).loadPointsConfig(languageCode);
});

final deedsProvider = FutureProvider<List<DeedEntry>>((ref) async {
  return ref.watch(localRepositoryProvider).loadDeeds();
});

final weeklyScoreProvider = FutureProvider<int>((ref) async {
  return ref.watch(scoreServiceProvider).weeklyScore();
});

final diaryProvider = FutureProvider<List<DiaryEntry>>((ref) async {
  return ref.watch(localRepositoryProvider).loadDiary();
});

final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(scoreRepositoryProvider).fetchLeaderboard();
});
