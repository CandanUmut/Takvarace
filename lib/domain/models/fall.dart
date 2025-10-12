class FallEntry {
  FallEntry({
    required this.timestamp,
    required this.resolved,
    required this.repentance,
    required this.pointsAwarded,
  });

  factory FallEntry.fromJson(Map<String, dynamic> json) => FallEntry(
        timestamp: json['ts'] as int,
        resolved: json['resolved'] as bool? ?? false,
        repentance: (json['repentance'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, value)),
        pointsAwarded: json['points_awarded'] as int? ?? 0,
      );

  final int timestamp;
  final bool resolved;
  final Map<String, dynamic> repentance;
  final int pointsAwarded;

  Map<String, dynamic> toJson() => {
        'ts': timestamp,
        'resolved': resolved,
        'repentance': repentance,
        'points_awarded': pointsAwarded,
      };
}
