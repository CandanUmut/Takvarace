import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

import '../../core/utils/week.dart';
import '../../data/local/repo_local.dart';
import '../../data/remote/repo_score.dart';
import '../models/deed.dart';
import '../models/user_profile.dart';

class ScoreService {
  ScoreService(this._localRepository, this._scoreRepository);

  final LocalRepository _localRepository;
  final ScoreRepository _scoreRepository;

  Future<Map<String, dynamic>> loadPointsConfig(String languageCode) async {
    final code = languageCode.startsWith('tr') ? 'tr' : 'en';
    final data = await rootBundle.loadString('assets/config/points.$code.json');
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<int> applyDeeds(List<DeedEntry> entries) async {
    final existing = await _localRepository.loadDeeds();
    final updated = [...existing, ...entries];
    await _localRepository.saveDeeds(updated);
    final delta = entries.map((e) => e.points).sum;
    if (delta != 0) {
      await _scoreRepository.upsertWeeklyScore(scoreDelta: delta);
    }
    return delta;
  }

  Future<int> weeklyScore() async {
    final weekStart = WeekUtils.weekStart(DateTime.now());
    return _localRepository.totalScoreForWeek(weekStart);
  }

  Future<void> registerProfile(UserProfile profile) async {
    await _scoreRepository.ensureUser(profile);
  }
}
