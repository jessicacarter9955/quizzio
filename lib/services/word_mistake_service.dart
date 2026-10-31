import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/models/vocabulary_word.dart';
import 'package:wordweaver/services/pattern_engine.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/vocabulary_service.dart';

/// One vocabulary item across quiz modes, with its real answer history.
/// The identity uses BOTH expressions and their direction: homographs with
/// different meanings, and reversed language pairs, never get mixed up.
class WordMistakeRecord {
  const WordMistakeRecord({
    required this.key,
    required this.pairKey,
    required this.source,
    required this.target,
    required this.topics,
    required this.wrong,
    required this.correct,
    required this.wrongByMode,
    required this.lastAttempt,
    this.lastWrong,
  });

  final String key;
  final String pairKey;
  final String source;
  final String target;
  final List<String> topics;
  final int wrong;
  final int correct;
  final Map<String, int> wrongByMode;
  final DateTime lastAttempt;
  final DateTime? lastWrong;

  int get attempts => wrong + correct;
  double get errorRate => attempts == 0 ? 0 : wrong / attempts;
  String get topic => topics.isEmpty ? 'uncategorized' : topics.first;

  VocabularyWord toVocabularyWord() => VocabularyWord(
        id: key,
        sourceWord: source,
        targetWord: target,
        languagePairKey: pairKey,
        topic: topic,
        createdAt: lastAttempt,
      );

  factory WordMistakeRecord.fromJson(Map<String, dynamic> data) {
    return WordMistakeRecord(
      key: data['key'] as String,
      pairKey: data['pairKey'] as String,
      source: data['source'] as String,
      target: data['target'] as String,
      topics: (data['topics'] as List<dynamic>? ?? [])
          .map((value) => value.toString()).toList(),
      wrong: (data['wrong'] as num?)?.toInt() ?? 0,
      correct: (data['correct'] as num?)?.toInt() ?? 0,
      wrongByMode: (data['wrongByMode'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as num).toInt())),
      lastAttempt: DateTime.parse(data['lastAttempt'] as String),
      lastWrong: data['lastWrong'] == null
          ? null : DateTime.tryParse(data['lastWrong'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'pairKey': pairKey,
        'source': source,
        'target': target,
        'topics': topics,
        'wrong': wrong,
        'correct': correct,
        'wrongByMode': wrongByMode,
        'lastAttempt': lastAttempt.toIso8601String(),
        'lastWrong': lastWrong?.toIso8601String(),
      };
}

class WordMistakeService extends ChangeNotifier {
  static const storageKey = 'wordweaver.word_mistakes.v1';
  static const writingHistoryKey = 'wordweaver.pattern.writing.v1';
  static final WordMistakeService _instance = WordMistakeService._internal();
  factory WordMistakeService() => _instance;

  WordMistakeService._internal() {
    ready = _load();
  }

  late final Future<void> ready;
  final Map<String, WordMistakeRecord> _records = {};
  Future<void> _writeQueue = Future<void>.value();
  bool _writingMigrated = false;

  List<WordMistakeRecord> get mistakes => List.unmodifiable(
      _records.values.where((record) => record.wrong > 0));
  int get mistakenWordCount => _records.values.where((r) => r.wrong > 0).length;
  int get totalMistakes => _records.values.fold(0, (sum, row) => sum + row.wrong);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(storageKey);
      if (saved != null) {
        final data = jsonDecode(saved) as Map<String, dynamic>;
        _writingMigrated = data['writingMigrated'] == true;
        for (final raw in data['records'] as List<dynamic>? ?? []) {
          try {
            final item = WordMistakeRecord.fromJson(raw as Map<String, dynamic>);
            _records[item.key] = item;
          } catch (error) {
            debugPrint('Skipping malformed word history entry: $error');
          }
        }
      }
      if (!_writingMigrated) {
        await _migrateWritingHistory(prefs);
        // Keep the migration marker in the SAME payload as the counters.
        // An interrupted launch cannot double-import old writing attempts.
        _writingMigrated = true;
        await _save();
      }
    } catch (error) {
      debugPrint('Unable to load word mistake history: $error');
    }
    notifyListeners();
  }

  Future<void> _migrateWritingHistory(SharedPreferences prefs) async {
    final old = prefs.getString(writingHistoryKey);
    if (old == null || old.isEmpty) return;
    List<dynamic> history;
    try {
      history = jsonDecode(old) as List<dynamic>;
    } catch (error) {
      debugPrint('Old writing history cannot be imported: $error');
      return;
    }
    final lookup = <String, Map<String, VocabularyWord>>{};
    await Future.wait([VocabularyService().ready, TopicService().ready]);
    for (final raw in history) {
      if (raw is! Map<String, dynamic>) continue;
      final pair = (raw['pair'] ?? '').toString();
      final source = (raw['source'] ?? '').toString().trim();
      final target = (raw['target'] ?? '').toString().trim();
      if (pair.split('_').length != 2 || source.isEmpty || target.isEmpty ||
          raw['correct'] is! bool) continue;
      final vocabulary = lookup.putIfAbsent(pair, () {
        final all = VocabularyService().getWordsForQuiz(
          pair, TopicService().topics.map((t) => t.id).toList(), 0x7fffffff);
        return {for (final word in all) PatternEngine.identity(word): word};
      });
      final fallback = VocabularyWord(
        id: (raw['word'] ?? '').toString(), sourceWord: source,
        targetWord: target, languagePairKey: pair,
        topic: 'uncategorized', createdAt: DateTime.now(),
      );
      final word = vocabulary[PatternEngine.identity(fallback)] ?? fallback;
      final when = DateTime.tryParse((raw['at'] ?? '').toString()) ?? DateTime.now();
      _apply(word, raw['correct'] as bool, 'writing', when);
    }
  }

  void _apply(VocabularyWord word, bool correct, String mode, DateTime when) {
    final key = PatternEngine.identity(word);
    final previous = _records[key];
    final topics = <String>{...?previous?.topics};
    if (word.topic.isNotEmpty && word.topic != 'uncategorized') {
      topics.add(word.topic);
    }
    if (topics.isEmpty) topics.add('uncategorized');
    if (topics.length > 1) topics.remove('uncategorized');
    final byMode = Map<String, int>.from(previous?.wrongByMode ?? {});
    if (!correct) byMode[mode] = (byMode[mode] ?? 0) + 1;
    final oldWrong = previous?.lastWrong;
    _records[key] = WordMistakeRecord(
      key: key, pairKey: word.languagePairKey,
      source: word.sourceWord, target: word.targetWord,
      topics: topics.toList(),
      wrong: (previous?.wrong ?? 0) + (correct ? 0 : 1),
      correct: (previous?.correct ?? 0) + (correct ? 1 : 0),
      wrongByMode: byMode,
      lastAttempt: previous == null || when.isAfter(previous.lastAttempt)
          ? when : previous.lastAttempt,
      lastWrong: correct ? oldWrong
          : (oldWrong == null || when.isAfter(oldWrong) ? when : oldWrong),
    );
  }

  Future<void> recordAnswer({
    required VocabularyWord word,
    required bool isCorrect,
    required String mode,
  }) async {
    await ready;
    _apply(word, isCorrect, mode, DateTime.now());
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final snapshot = jsonEncode({
      'version': 1,
      'writingMigrated': _writingMigrated,
      'records': _records.values.map((record) => record.toJson()).toList(),
    });
    _writeQueue = _writeQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, snapshot);
    }).catchError((Object error) {
      debugPrint('Unable to persist word mistake history: $error');
    });
    await _writeQueue;
  }
}
