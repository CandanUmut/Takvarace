class ZikrState {
  const ZikrState({
    required this.phrase,
    required this.goal,
    required this.count,
  });

  factory ZikrState.initial() => const ZikrState(
        phrase: 'Subhanallah',
        goal: 100,
        count: 0,
      );

  factory ZikrState.fromJson(Map<String, dynamic> json) => ZikrState(
        phrase: json['phrase'] as String? ?? 'Subhanallah',
        goal: (json['goal'] as num?)?.toInt() ?? 100,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );

  final String phrase;
  final int goal;
  final int count;

  Map<String, dynamic> toJson() => {
        'phrase': phrase,
        'goal': goal,
        'count': count,
      };

  ZikrState copyWith({
    String? phrase,
    int? goal,
    int? count,
  }) {
    return ZikrState(
      phrase: phrase ?? this.phrase,
      goal: goal ?? this.goal,
      count: count ?? this.count,
    );
  }
}
