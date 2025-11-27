import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  String? _username;
  String? get username => _username;

  int _totalQuizzesTaken = 0;
  int get totalQuizzesTaken => _totalQuizzesTaken;

  int _totalCorrectAnswers = 0;
  int get totalCorrectAnswers => _totalCorrectAnswers;

  int _totalQuestions = 0;
  int get totalQuestions => _totalQuestions;

  double get overallAccuracy =>
      _totalQuestions > 0 ? _totalCorrectAnswers / _totalQuestions : 0.0;

  DateTime? _lastQuizDate;
  DateTime? get lastQuizDate => _lastQuizDate;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username');
    _totalQuizzesTaken = prefs.getInt('totalQuizzesTaken') ?? 0;
    _totalCorrectAnswers = prefs.getInt('totalCorrectAnswers') ?? 0;
    _totalQuestions = prefs.getInt('totalQuestions') ?? 0;
    final lastQuizTimestamp = prefs.getString('lastQuizDate');
    if (lastQuizTimestamp != null) {
      _lastQuizDate = DateTime.parse(lastQuizTimestamp);
    }
    notifyListeners();
  }

  Future<void> setUsername(String username) async {
    _username = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    notifyListeners();
  }

  Future<void> recordQuizResults({
    required int questionsCount,
    required int correctCount,
    required int incorrectCount,
  }) async {
    _totalQuizzesTaken++;
    _totalCorrectAnswers += correctCount;
    _totalQuestions += questionsCount;
    _lastQuizDate = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalQuizzesTaken', _totalQuizzesTaken);
    await prefs.setInt('totalCorrectAnswers', _totalCorrectAnswers);
    await prefs.setInt('totalQuestions', _totalQuestions);
    await prefs.setString('lastQuizDate', _lastQuizDate!.toIso8601String());
    notifyListeners();
  }

  Future<void> resetStats() async {
    _totalQuizzesTaken = 0;
    _totalCorrectAnswers = 0;
    _totalQuestions = 0;
    _lastQuizDate = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('totalQuizzesTaken');
    await prefs.remove('totalCorrectAnswers');
    await prefs.remove('totalQuestions');
    await prefs.remove('lastQuizDate');
    notifyListeners();
  }

  Future<void> updateWordsLearned(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final currentWords = prefs.getInt('wordsLearned') ?? 0;
    await prefs.setInt('wordsLearned', currentWords + count);
    notifyListeners();
  }

  Map<String, dynamic> getStatsSummary() {
    return {
      'totalQuizzesTaken': _totalQuizzesTaken,
      'totalCorrectAnswers': _totalCorrectAnswers,
      'totalQuestions': _totalQuestions,
      'overallAccuracy': overallAccuracy,
      'lastQuizDate': _lastQuizDate?.toIso8601String(),
    };
  }
}
