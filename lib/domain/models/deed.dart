import 'dart:convert';

enum DeedSource { form, freeText }

enum DeedType {
  prayer,
  quran,
  dhikr,
  walk,
  istighfar,
  repentance,
  custom,
}

class DeedEntry {
  DeedEntry({
    required this.timestamp,
    required this.type,
    required this.points,
    required this.meta,
    required this.source,
    this.note,
    this.languageCode,
  });

  factory DeedEntry.fromJson(Map<String, dynamic> json) => DeedEntry(
        timestamp: json['ts'] as int,
        type: DeedType.values.firstWhere(
          (element) => element.name == (json['type'] as String? ?? 'custom'),
          orElse: () => DeedType.custom,
        ),
        points: json['points'] as int? ?? 0,
        meta: (json['meta'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, value),
        ),
        source: DeedSource.values.firstWhere(
          (element) => element.name == (json['source'] as String? ?? 'form'),
          orElse: () => DeedSource.form,
        ),
        note: json['note'] as String?,
        languageCode: json['lang'] as String?,
      );

  final int timestamp;
  final DeedType type;
  final int points;
  final Map<String, dynamic> meta;
  final DeedSource source;
  final String? note;
  final String? languageCode;

  Map<String, dynamic> toJson() => {
        'ts': timestamp,
        'type': type.name,
        'points': points,
        'meta': meta,
        'source': source.name,
        if (note != null) 'note': note,
        if (languageCode != null) 'lang': languageCode,
      };

  String toEncoded() => jsonEncode(toJson());
}
