import 'dart:convert';

class UserProfile {
  UserProfile({
    required this.alias,
    required this.languageCode,
    required this.shareScore,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        alias: json['alias'] as String,
        languageCode: json['languageCode'] as String? ?? 'en',
        shareScore: json['shareScore'] as bool? ?? true,
      );

  final String alias;
  final String languageCode;
  final bool shareScore;

  Map<String, dynamic> toJson() => {
        'alias': alias,
        'languageCode': languageCode,
        'shareScore': shareScore,
      };

  String toEncoded() => jsonEncode(toJson());

  static UserProfile? tryDecode(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return UserProfile.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  UserProfile copyWith({String? alias, String? languageCode, bool? shareScore}) {
    return UserProfile(
      alias: alias ?? this.alias,
      languageCode: languageCode ?? this.languageCode,
      shareScore: shareScore ?? this.shareScore,
    );
  }
}
