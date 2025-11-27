class SavedWord {
  final String id;
  final String sourceWord;
  final String targetWord;
  final String languagePairKey;
  final String topic;
  final DateTime addedAt;

  SavedWord({
    required this.id,
    required this.sourceWord,
    required this.targetWord,
    required this.languagePairKey,
    required this.topic,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceWord': sourceWord,
    'targetWord': targetWord,
    'languagePairKey': languagePairKey,
    'topic': topic,
    'addedAt': addedAt.toIso8601String(),
  };

  factory SavedWord.fromJson(Map<String, dynamic> json) => SavedWord(
    id: json['id'] as String,
    sourceWord: json['sourceWord'] as String,
    targetWord: json['targetWord'] as String,
    languagePairKey: json['languagePairKey'] as String,
    topic: json['topic'] as String,
    addedAt: DateTime.parse(json['addedAt'] as String),
  );
}
