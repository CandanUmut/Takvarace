class StreakState {
  StreakState({
    required this.lastFallTimestamp,
    required this.currentSeconds,
  });

  factory StreakState.initial() => StreakState(
        lastFallTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        currentSeconds: 0,
      );

  factory StreakState.fromJson(Map<String, dynamic> json) => StreakState(
        lastFallTimestamp: json['last_fall_ts'] as int? ?? 0,
        currentSeconds: json['current_seconds'] as int? ?? 0,
      );

  final int lastFallTimestamp;
  final int currentSeconds;

  Map<String, dynamic> toJson() => {
        'last_fall_ts': lastFallTimestamp,
        'current_seconds': currentSeconds,
      };

  StreakState copyWith({int? lastFallTimestamp, int? currentSeconds}) {
    return StreakState(
      lastFallTimestamp: lastFallTimestamp ?? this.lastFallTimestamp,
      currentSeconds: currentSeconds ?? this.currentSeconds,
    );
  }
}
