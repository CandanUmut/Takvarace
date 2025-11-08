class PomodoroSettings {
  const PomodoroSettings({
    required this.focusMinutes,
    required this.breakMinutes,
  });

  factory PomodoroSettings.initial() => const PomodoroSettings(
        focusMinutes: 25,
        breakMinutes: 5,
      );

  factory PomodoroSettings.fromJson(Map<String, dynamic> json) => PomodoroSettings(
        focusMinutes: (json['focusMinutes'] as num?)?.toInt() ?? 25,
        breakMinutes: (json['breakMinutes'] as num?)?.toInt() ?? 5,
      );

  final int focusMinutes;
  final int breakMinutes;

  Map<String, dynamic> toJson() => {
        'focusMinutes': focusMinutes,
        'breakMinutes': breakMinutes,
      };

  PomodoroSettings copyWith({
    int? focusMinutes,
    int? breakMinutes,
  }) {
    return PomodoroSettings(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
    );
  }
}
