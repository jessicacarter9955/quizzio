import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stats.dart';

class StatsService extends ChangeNotifier {
  static final StatsService _instance = StatsService._internal();
  factory StatsService() => _instance;

  StatsService._internal() {
    _load();
  }

  Stats _stats = const Stats();
  Stats get stats => _stats;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('stats');
      if (data != null) {
        _stats = Stats.fromJson(jsonDecode(data) as Map<String, dynamic>);
      } else {
        _stats = const Stats();
        await _save();
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('stats', jsonEncode(_stats.toJson()));
    } catch (_) {}
  }

  Future<void> reset() async {
    _stats = const Stats();
    await _save();
    notifyListeners();
  }

  Future<void> recordAnswer({
    required bool isCorrect,
    required String topicId,
    required String languagePairKey,
  }) async {
    final perTopic = Map<String, TopicStats>.from(_stats.perTopic);
    final perPair = Map<String, TopicStats>.from(_stats.perLangPair);

    final t = perTopic[topicId] ?? const TopicStats();
    perTopic[topicId] = t.copyWith(
      attempts: t.attempts + 1,
      correct: t.correct + (isCorrect ? 1 : 0),
    );

    final p = perPair[languagePairKey] ?? const TopicStats();
    perPair[languagePairKey] = p.copyWith(
      attempts: p.attempts + 1,
      correct: p.correct + (isCorrect ? 1 : 0),
    );

    _stats = _stats.copyWith(
      totalQuestions: _stats.totalQuestions + 1,
      correct: _stats.correct + (isCorrect ? 1 : 0),
      incorrect: _stats.incorrect + (isCorrect ? 0 : 1),
      perTopic: perTopic,
      perLangPair: perPair,
    );
    await _save();
    notifyListeners();
  }

  Future<void> recordQuizEnd({
    required int totalQuestionsInQuiz,
    required Duration duration,
  }) async {
    final totalQs = _stats.totalQuestions == 0 ? 1 : _stats.totalQuestions;
    final prevAvg = _stats.avgTimePerQuestionSec;
    final totalTimeSoFar = prevAvg * totalQs;
    final newAvg =
        (totalTimeSoFar + duration.inSeconds) /
        (totalQs + totalQuestionsInQuiz);

    final now = DateTime.now();
    var streak = _stats.streakDays;
    if (_stats.lastPlayedAt != null) {
      final last = DateTime(
        _stats.lastPlayedAt!.year,
        _stats.lastPlayedAt!.month,
        _stats.lastPlayedAt!.day,
      );
      final today = DateTime(now.year, now.month, now.day);
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    _stats = _stats.copyWith(
      totalQuizzes: _stats.totalQuizzes + 1,
      avgTimePerQuestionSec: newAvg,
      lastPlayedAt: now,
      streakDays: streak,
    );
    await _save();
    notifyListeners();
  }
}
