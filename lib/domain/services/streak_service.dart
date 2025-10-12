import '../../data/local/repo_local.dart';
import '../models/streak.dart';

class StreakService {
  StreakService(this._localRepository);

  final LocalRepository _localRepository;

  Future<StreakState> load() => _localRepository.loadStreak();

  Future<StreakState> recordFall() async {
    final now = DateTime.now();
    final streak = StreakState(
      lastFallTimestamp: now.millisecondsSinceEpoch ~/ 1000,
      currentSeconds: 0,
    );
    await _localRepository.saveStreak(streak);
    return streak;
  }

  Future<StreakState> restore() async {
    final existing = await _localRepository.loadStreak();
    final now = DateTime.now();
    final diff = now.millisecondsSinceEpoch ~/ 1000 - existing.lastFallTimestamp;
    final updated = existing.copyWith(currentSeconds: diff);
    await _localRepository.saveStreak(updated);
    return updated;
  }
}
