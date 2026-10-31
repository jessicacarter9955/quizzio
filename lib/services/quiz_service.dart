import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/models/quiz_question.dart';
import 'package:wordweaver/models/quiz_result.dart';
import 'package:wordweaver/services/vocabulary_service.dart';

class QuizService extends ChangeNotifier {
  // Singleton instance so all listeners share the same history state
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;

  QuizService._internal() : vocabularyService = VocabularyService() {
    _loadQuizHistory();
  }

  final VocabularyService vocabularyService;
  List<QuizResult> _quizHistory = [];
  List<QuizResult> get quizHistory => _quizHistory;

  // 0 means MAX: every distinct question in the selected topic(s).
  int _questionCount = 0;
  int get questionCount => _questionCount;

  int _answerOptionCount = 3;
  int get answerOptionCount => _answerOptionCount;

  // By default, focus on one available, selected topic.
  String _topicMode = 'single';
  String get topicMode => _topicMode;

  Future<void> setQuestionCount(int count) async {
    _questionCount = count < 0 ? 0 : count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quizQuestionCount', _questionCount);
    notifyListeners();
  }

  Future<void> setAnswerOptionCount(int count) async {
    _answerOptionCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quizAnswerOptionCount', count);
    notifyListeners();
  }

  Future<void> setTopicMode(String mode) async {
    _topicMode = mode == 'mixed' ? 'mixed' : 'single';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quizTopicMode', _topicMode);
    notifyListeners();
  }

  Future<void> _loadQuizHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _questionCount = prefs.getInt('quizQuestionCount') ?? 0;
      _answerOptionCount = prefs.getInt('quizAnswerOptionCount') ?? 3;
      _topicMode = prefs.getString('quizTopicMode') == 'mixed' ? 'mixed' : 'single';
      final historyData = prefs.getString('quizHistory');
      if (historyData != null) {
        final List<dynamic> decoded = jsonDecode(historyData) as List;
        _quizHistory = decoded
            .map((json) => QuizResult.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      notifyListeners();
    } catch (e) {
      _quizHistory = [];
      debugPrint('Error loading quiz history: $e');
    }
  }

  Future<void> _saveQuizHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'quizHistory',
        jsonEncode(_quizHistory.map((r) => r.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving quiz history: $e');
    }
  }

  List<QuizQuestion> generateQuiz(
    String languagePairKey,
    List<String> topicIds,
    int questionCount, {
    int answerOptionCount = 3,
  }) {
    final words = vocabularyService.getWordsForQuiz(
      languagePairKey,
      topicIds,
      questionCount <= 0 ? 0x7fffffff : questionCount,
    );
    final questions = <QuizQuestion>[];

    for (var word in words) {
      final wrongAnswers = vocabularyService.getRandomWrongAnswers(
        languagePairKey,
        word.targetWord,
        answerOptionCount,
      );
      if (wrongAnswers.isEmpty) {
        continue;
      }
      final options = [word.targetWord, ...wrongAnswers];
      options.shuffle();
      final correctIndex = options.indexOf(word.targetWord);

      questions.add(
        QuizQuestion(
          word: word,
          options: options,
          correctIndex: correctIndex,
          wrongAnswers: wrongAnswers,
          topic: word.topic,
        ),
      );
    }

    return questions;
  }

  Future<void> saveQuizResult(QuizResult result) async {
    _quizHistory.insert(0, result);
    if (_quizHistory.length > 50) {
      _quizHistory = _quizHistory.take(50).toList();
    }
    await _saveQuizHistory();
    notifyListeners();
  }

  QuizResult createResult({
    required String languagePairKey,
    required List<String> topics,
    required int correctAnswers,
    required int incorrectAnswers,
    required int timeTaken,
  }) {
    final totalQuestions = correctAnswers + incorrectAnswers;
    return QuizResult(
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      timestamp: DateTime.now(),
      languagePairKey: languagePairKey,
      topicIds: topics,
    );
  }

  List<QuizResult> getRecentResults(int count) {
    return _quizHistory.take(count).toList();
  }
}
