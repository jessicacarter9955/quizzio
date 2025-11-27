import 'vocabulary_word.dart';

class QuizQuestion {
  final VocabularyWord word;
  final List<String> options;
  final int correctIndex;
  final List<String> wrongAnswers;
  final String topic;

  QuizQuestion({
    required this.word,
    required this.options,
    required this.correctIndex,
    this.wrongAnswers = const [],
    this.topic = '',
  });

  String get questionText => word.sourceWord;
  String get correctAnswer => word.targetWord;

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;

  @override
  String toString() =>
      'QuizQuestion(question: $questionText, correct: $correctAnswer)';
}
