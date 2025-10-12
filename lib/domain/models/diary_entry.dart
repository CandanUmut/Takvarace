class DiaryEntry {
  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.timestamp,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
        timestamp: json['timestamp'] as int? ?? 0,
      );

  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final int timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'tags': tags,
        'timestamp': timestamp,
      };
}
