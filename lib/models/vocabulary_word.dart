class VocabularyWord {
  final String id;
  final String sourceWord;
  final String targetWord;
  final String languagePairKey;
  final String topic;
  final DateTime createdAt;

  VocabularyWord({
    required this.id,
    required this.sourceWord,
    required this.targetWord,
    required this.languagePairKey,
    required this.topic,
    required this.createdAt,
  });

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      id: json['id'] as String,
      sourceWord: json['sourceWord'] as String,
      targetWord: json['targetWord'] as String,
      languagePairKey: json['languagePairKey'] as String,
      topic: json['topic'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceWord': sourceWord,
      'targetWord': targetWord,
      'languagePairKey': languagePairKey,
      'topic': topic,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyWord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VocabularyWord($sourceWord -> $targetWord)';
}
