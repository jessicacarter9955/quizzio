class QuizResult {
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final DateTime timestamp;
  final String languagePairKey;
  final List<String> topicIds;
  final double accuracy;

  QuizResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.timestamp,
    required this.languagePairKey,
    required this.topicIds,
  }) : accuracy = totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;

  QuizResult.withLanguageAndTopics({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.timestamp,
    required String languagePair,
    required List<String> topics,
  }) : languagePairKey = languagePair,
       topicIds = topics,
       accuracy = totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      incorrectAnswers: json['incorrectAnswers'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      languagePairKey: json['languagePairKey'] as String,
      topicIds: (json['topicIds'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'timestamp': timestamp.toIso8601String(),
      'languagePairKey': languagePairKey,
      'topicIds': topicIds,
    };
  }

  @override
  String toString() =>
      'QuizResult(accuracy: ${(accuracy * 100).toStringAsFixed(1)}%, correct: $correctAnswers/$totalQuestions)';
}
