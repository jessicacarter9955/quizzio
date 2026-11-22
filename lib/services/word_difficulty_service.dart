import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/models/vocabulary_word.dart';

enum WordDifficulty { easy, medium, hard }

/// Persistent traffic-light ratings shared between Patterns and My List.
class WordDifficultyService extends ChangeNotifier {
  static final WordDifficultyService _instance = WordDifficultyService._internal();
  factory WordDifficultyService() => _instance;

  WordDifficultyService._internal() {
    _ready = _load();
  }

  static const _storageKey = 'wordweaver.wordDifficulty.v1';
  Map<String, WordDifficulty> _ratings = {};
  late final Future<void> _ready;
  Future<void> get ready => _ready;

  static String _normalized(String value) => value.trim().toLowerCase()
      .replaceAll(RegExp(r'^[^\w\p{L}\p{N}]+', unicode: true), '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]+', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  static String identityForParts({
    required String languagePairKey,
    required String sourceWord,
    required String targetWord,
  }) => '$languagePairKey|\u0001${_normalized(sourceWord)}|\u0001${_normalized(targetWord)}';

  String identity(VocabularyWord word) => identityForParts(
    languagePairKey: word.languagePairKey,
    sourceWord: word.sourceWord,
    targetWord: word.targetWord,
  );

  WordDifficulty? getDifficulty(VocabularyWord word) => _ratings[identity(word)];

  WordDifficulty? getDifficultyForParts({
    required String languagePairKey,
    required String sourceWord,
    required String targetWord,
  }) => _ratings[identityForParts(
    languagePairKey: languagePairKey,
    sourceWord: sourceWord,
    targetWord: targetWord,
  )];

  Future<void> setDifficulty(VocabularyWord word, WordDifficulty? difficulty) =>
      _set(identity(word), difficulty);

  Future<void> setDifficultyForParts({
    required String languagePairKey,
    required String sourceWord,
    required String targetWord,
    required WordDifficulty? difficulty,
  }) => _set(identityForParts(
    languagePairKey: languagePairKey,
    sourceWord: sourceWord,
    targetWord: targetWord,
  ), difficulty);

  Future<void> _set(String key, WordDifficulty? difficulty) async {
    await ready;
    if (difficulty == null) {
      if (_ratings.remove(key) == null) return;
    } else {
      if (_ratings[key] == difficulty) return;
      _ratings[key] = difficulty;
    }
    await _save();
    notifyListeners();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final loaded = <String, WordDifficulty>{};
        for (final entry in decoded.entries) {
          for (final difficulty in WordDifficulty.values) {
            if (entry.value == difficulty.name) {
              loaded[entry.key.toString()] = difficulty;
              break;
            }
          }
        }
        _ratings = loaded;
      }
    } catch (e) {
      debugPrint('Error loading word difficulties: $e');
    }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_ratings.map((key, value) => MapEntry(key, value.name))),
      );
    } catch (e) {
      debugPrint('Error saving word difficulties: $e');
    }
  }
}
