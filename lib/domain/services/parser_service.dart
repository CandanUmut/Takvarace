import 'dart:math';

import '../models/deed.dart';

class ParsedResult {
  ParsedResult({required this.entries, required this.suggestions});

  final List<DeedEntry> entries;
  final List<String> suggestions;
}

class ParserService {
  ParserService({required this.pointsConfig});

  final Map<String, dynamic> pointsConfig;

  ParsedResult parse(String input, {required String languageCode}) {
    final lower = input.toLowerCase();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final entries = <DeedEntry>[];
    final suggestions = <String>[];

    void addEntry(DeedType type, int points, Map<String, dynamic> meta, {String? note}) {
      entries.add(DeedEntry(
        timestamp: now,
        type: type,
        points: points,
        meta: meta,
        source: DeedSource.freeText,
        note: note,
        languageCode: languageCode,
      ));
    }

    final patterns = languageCode.startsWith('tr') ? _trPatterns : _enPatterns;
    for (final pattern in patterns.entries) {
      final regex = RegExp(pattern.value, caseSensitive: false, multiLine: true);
      final matches = regex.allMatches(lower);
      for (final match in matches) {
        switch (pattern.key) {
          case 'quran':
            final value = int.tryParse(match.group(2) ?? '0') ?? 0;
            final unit = match.group(3) ?? '';
            final points = _pointsFor('quran', value: value, unit: unit);
            addEntry(DeedType.quran, points, {'amount': value, 'unit': unit});
            break;
          case 'dhikr':
            final value = int.tryParse(match.group(2) ?? '0') ?? 0;
            final points = _pointsFor('dhikr', value: value);
            addEntry(DeedType.dhikr, points, {'repetitions': value});
            break;
          case 'walk':
            final value = int.tryParse(match.group(2) ?? '0') ?? 0;
            final points = _pointsFor('walk', value: value);
            addEntry(DeedType.walk, points, {'minutes': value});
            break;
          case 'istighfar':
            final value = int.tryParse(match.group(2) ?? '0') ?? 0;
            final points = _pointsFor('istighfar', value: value);
            addEntry(DeedType.istighfar, points, {'repetitions': value});
            break;
          case 'prayer':
            final prayer = match.group(2) ?? '';
            final points = _pointsFor('prayer');
            addEntry(DeedType.prayer, points, {'prayer': prayer});
            break;
          default:
            suggestions.add(match.group(0) ?? '');
        }
      }
    }

    if (entries.isEmpty) {
      suggestions.add(input.trim());
    }

    return ParsedResult(entries: entries, suggestions: suggestions);
  }

  int _pointsFor(String key, {int? value, String? unit}) {
    final config = pointsConfig[key];
    if (config is int) {
      return config;
    }
    if (config is Map<String, dynamic>) {
      if (config.containsKey('steps')) {
        final steps = config['steps'] as Map<String, dynamic>;
        final minutes = value ?? 0;
        final match = steps.entries
            .map((e) => MapEntry(int.tryParse(e.key) ?? 0, e.value as int))
            .where((entry) => entry.key <= minutes)
            .fold<MapEntry<int, int>?>(null, (previous, element) {
          if (previous == null) return element;
          if (element.key > previous.key) return element;
          return previous;
        });
        if (match != null) {
          return match.value;
        }
      }
      if (config.containsKey('unit')) {
        final unitKey = unit?.contains('page') == true || unit?.contains('sayfa') == true
            ? 'page'
            : 'minute';
        final base = config[unitKey] as int? ?? 0;
        final amount = value ?? 1;
        final block = config['block'] as int? ?? 1;
        final multiplier = (amount / block).ceil().clamp(1, double.infinity).toInt();
        return base * max(1, multiplier);
      }
    }
    return pointsConfig['default'] as int? ?? 0;
  }

  static const Map<String, String> _enPatterns = {
    'quran': r'(quran|recite)[^0-9]*(\d+)\s*(min|minutes|page|pages)',
    'dhikr': r'(dhikr|zikr|tasbih)[^0-9]*(\d+)\s*(x|times)',
    'walk': r'(walk|walking)[^0-9]*(\d+)\s*(min|minutes)',
    'istighfar': r'(istighfar)[^0-9]*(\d+)\s*(x|times)',
    'prayer': r'(prayer|salah|salat)[^a-z]*(fajr|zuhr|asr|maghrib|isha)',
  };

  static const Map<String, String> _trPatterns = {
    'quran': r"(kur[’']?an|kuran)[^0-9]*(\d+)\s*(dk|dakika|sayfa)",
    'dhikr': r'(zikir|tesbih)[^0-9]*(\d+)\s*(x|kez)',
    'walk': r'(y[üu]r[üu]y[üu]?[sş])[^0-9]*(\d+)\s*(dk|dakika)',
    'istighfar': r'(istiğfar|est[ae]ğfirullah)[^0-9]*(\d+)\s*(x|kez)',
    'prayer': r'(namaz)[^a-zçğıöşü]*(sabah|öğle|ikindi|akşam|yatsı)',
  };
}
