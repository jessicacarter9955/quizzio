class Stats {
  final int totalQuizzes;
  final int totalQuestions;
  final int correct;
  final int incorrect;
  final DateTime? lastPlayedAt;
  final Map<String, TopicStats> perTopic;
  final Map<String, TopicStats> perLangPair;
  final double avgTimePerQuestionSec;
  final int streakDays;

  const Stats({
    this.totalQuizzes = 0,
    this.totalQuestions = 0,
    this.correct = 0,
    this.incorrect = 0,
    this.lastPlayedAt,
    this.perTopic = const {},
    this.perLangPair = const {},
    this.avgTimePerQuestionSec = 0.0,
    this.streakDays = 0,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      totalQuizzes: json['totalQuizzes'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      incorrect: json['incorrect'] as int? ?? 0,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.parse(json['lastPlayedAt'] as String)
          : null,
      perTopic:
          (json['perTopic'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              TopicStats.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      perLangPair:
          (json['perLangPair'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              TopicStats.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      avgTimePerQuestionSec:
          (json['avgTimePerQuestionSec'] as num?)?.toDouble() ?? 0.0,
      streakDays: json['streakDays'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuizzes': totalQuizzes,
      'totalQuestions': totalQuestions,
      'correct': correct,
      'incorrect': incorrect,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'perTopic': perTopic.map((key, value) => MapEntry(key, value.toJson())),
      'perLangPair': perLangPair.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'avgTimePerQuestionSec': avgTimePerQuestionSec,
      'streakDays': streakDays,
    };
  }

  double get accuracy {
    final total = correct + incorrect;
    return total > 0 ? correct / total : 0.0;
  }

  Stats copyWith({
    int? totalQuizzes,
    int? totalQuestions,
    int? correct,
    int? incorrect,
    DateTime? lastPlayedAt,
    Map<String, TopicStats>? perTopic,
    Map<String, TopicStats>? perLangPair,
    double? avgTimePerQuestionSec,
    int? streakDays,
  }) {
    return Stats(
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correct: correct ?? this.correct,
      incorrect: incorrect ?? this.incorrect,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      perTopic: perTopic ?? this.perTopic,
      perLangPair: perLangPair ?? this.perLangPair,
      avgTimePerQuestionSec:
          avgTimePerQuestionSec ?? this.avgTimePerQuestionSec,
      streakDays: streakDays ?? this.streakDays,
    );
  }
}

class TopicStats {
  final String topicId;
  final int attempts;
  final int correct;
  final DateTime? lastAttempt;

  const TopicStats({
    this.topicId = '',
    this.attempts = 0,
    this.correct = 0,
    this.lastAttempt,
  });

  factory TopicStats.fromJson(Map<String, dynamic> json) {
    return TopicStats(
      topicId: json['topicId'] as String? ?? '',
      attempts: json['attempts'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      lastAttempt: json['lastAttempt'] != null
          ? DateTime.parse(json['lastAttempt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'attempts': attempts,
      'correct': correct,
      'lastAttempt': lastAttempt?.toIso8601String(),
    };
  }

  double get accuracy {
    return attempts > 0 ? correct / attempts : 0.0;
  }

  TopicStats copyWith({
    String? topicId,
    int? attempts,
    int? correct,
    DateTime? lastAttempt,
  }) {
    return TopicStats(
      topicId: topicId ?? this.topicId,
      attempts: attempts ?? this.attempts,
      correct: correct ?? this.correct,
      lastAttempt: lastAttempt ?? this.lastAttempt,
    );
  }
}
