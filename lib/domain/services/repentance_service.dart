import '../../core/utils/week.dart';
import '../../data/local/repo_local.dart';
import '../models/deed.dart';
import '../models/fall.dart';
import 'score_service.dart';
import 'streak_service.dart';

class RepentanceService {
  RepentanceService(this._localRepository, this._scoreService, this._streakService);

  final LocalRepository _localRepository;
  final ScoreService _scoreService;
  final StreakService _streakService;

  Future<int> completeRepentance(Map<String, dynamic> actions) async {
    final now = DateTime.now();
    final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;
    final falls = await _localRepository.loadFalls();
    final weekStart = WeekUtils.weekStart(now);
    final weeklyResolved = falls
        .where((element) =>
            element.resolved &&
            DateTime.fromMillisecondsSinceEpoch(element.timestamp * 1000).isAfter(weekStart))
        .length;
    final multiplier = _multiplierFor(weeklyResolved);
    final base = 25;
    final recovery = 15;
    final points = (base * multiplier).round() + recovery;
    final fallEntry = FallEntry(
      timestamp: nowSeconds,
      resolved: true,
      repentance: actions,
      pointsAwarded: points,
    );
    falls.add(fallEntry);
    await _localRepository.saveFalls(falls);

    final deed = DeedEntry(
      timestamp: nowSeconds,
      type: DeedType.repentance,
      points: points,
      meta: actions,
      source: DeedSource.form,
    );
    await _scoreService.applyDeeds([deed]);
    await _streakService.restore();
    return points;
  }

  double _multiplierFor(int resolvedCount) {
    if (resolvedCount == 0) return 1.10;
    if (resolvedCount == 1) return 1.05;
    return 1.0;
  }
}
