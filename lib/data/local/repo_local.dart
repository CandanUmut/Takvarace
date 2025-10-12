import 'dart:convert';

import 'package:collection/collection.dart';

import '../../domain/models/deed.dart';
import '../../domain/models/diary_entry.dart';
import '../../domain/models/fall.dart';
import '../../domain/models/streak.dart';
import '../../domain/models/user_profile.dart';
import 'secure_store.dart';

class LocalRepository {
  LocalRepository(this._store);

  static const _profileKey = 'local_profile.json.enc';
  static const _deedsKey = 'deeds.json.enc';
  static const _fallsKey = 'falls.json.enc';
  static const _streakKey = 'streak.json.enc';
  static const _diaryKey = 'diary.json.enc';

  final SecureStore _store;

  Future<UserProfile?> loadProfile() async {
    final encoded = await _store.readEncrypted(_profileKey);
    return UserProfile.tryDecode(encoded);
  }

  Future<void> saveProfile(UserProfile profile) =>
      _store.writeEncrypted(_profileKey, profile.toEncoded());

  Future<List<DeedEntry>> loadDeeds() async {
    final encoded = await _store.readEncrypted(_deedsKey);
    if (encoded == null) return [];
    final list = (jsonDecode(encoded) as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(DeedEntry.fromJson).toList();
  }

  Future<void> saveDeeds(List<DeedEntry> deeds) async {
    final encoded = jsonEncode(deeds.map((e) => e.toJson()).toList());
    await _store.writeEncrypted(_deedsKey, encoded);
  }

  Future<List<FallEntry>> loadFalls() async {
    final encoded = await _store.readEncrypted(_fallsKey);
    if (encoded == null) return [];
    final list = (jsonDecode(encoded) as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(FallEntry.fromJson).toList();
  }

  Future<void> saveFalls(List<FallEntry> falls) async {
    final encoded = jsonEncode(falls.map((e) => e.toJson()).toList());
    await _store.writeEncrypted(_fallsKey, encoded);
  }

  Future<StreakState> loadStreak() async {
    final encoded = await _store.readEncrypted(_streakKey);
    if (encoded == null) return StreakState.initial();
    return StreakState.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
  }

  Future<void> saveStreak(StreakState streak) async {
    final encoded = jsonEncode(streak.toJson());
    await _store.writeEncrypted(_streakKey, encoded);
  }

  Future<String> exportAll() async {
    final profile = await loadProfile();
    final deeds = await loadDeeds();
    final falls = await loadFalls();
    final streak = await loadStreak();
    final diary = await loadDiary();
    final map = {
      'profile': profile?.toJson(),
      'deeds': deeds.map((e) => e.toJson()).toList(),
      'falls': falls.map((e) => e.toJson()).toList(),
      'streak': streak.toJson(),
      'diary': diary.map((e) => e.toJson()).toList(),
    };
    return jsonEncode(map);
  }

  Future<void> importAll(String payload) async {
    final map = jsonDecode(payload) as Map<String, dynamic>;
    final profileJson = map['profile'] as Map<String, dynamic>?;
    final profile = profileJson == null ? null : UserProfile.fromJson(profileJson);
    final deeds = (map['deeds'] as List<dynamic>? ?? [])
        .map((e) => DeedEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final falls = (map['falls'] as List<dynamic>? ?? [])
        .map((e) => FallEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final streakMap = map['streak'] as Map<String, dynamic>?;
    final streak = streakMap == null
        ? StreakState.initial()
        : StreakState.fromJson(streakMap);
    final diary = (map['diary'] as List<dynamic>? ?? [])
        .map((e) => DiaryEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    if (profile != null) {
      await saveProfile(profile);
    }
    await saveDeeds(deeds);
    await saveFalls(falls);
    await saveStreak(streak);
    await saveDiary(diary);
  }

  Future<int> totalScoreForWeek(DateTime weekStart) async {
    final deeds = await loadDeeds();
    final startMs = weekStart.millisecondsSinceEpoch;
    final endMs = weekStart.add(const Duration(days: 7)).millisecondsSinceEpoch;
    return deeds
        .where((e) => e.timestamp * 1000 >= startMs && e.timestamp * 1000 < endMs)
        .map((e) => e.points)
        .sum;
  }

  Future<List<DiaryEntry>> loadDiary() async {
    final encoded = await _store.readEncrypted(_diaryKey);
    if (encoded == null) return [];
    final list = (jsonDecode(encoded) as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(DiaryEntry.fromJson).toList();
  }

  Future<void> saveDiary(List<DiaryEntry> entries) async {
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _store.writeEncrypted(_diaryKey, encoded);
  }

  Future<String> exportDiary() async {
    final diary = await loadDiary();
    return jsonEncode(diary.map((e) => e.toJson()).toList());
  }

  Future<void> importDiaryPayload(String payload) async {
    final list = (jsonDecode(payload) as List<dynamic>)
        .map((e) => DiaryEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    await saveDiary(list);
  }
}
