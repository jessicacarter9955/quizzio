import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/models/saved_word.dart';
import 'package:wordweaver/models/vocabulary_word.dart';

class SavedWordsService extends ChangeNotifier {
  static final SavedWordsService _instance = SavedWordsService._internal();
  factory SavedWordsService() => _instance;

  SavedWordsService._internal() {
    _ready = _loadSavedWords();
  }

  static const _storageKey = 'saved_words';
  late final Future<void> _ready;
  Future<void> get ready => _ready;

  List<SavedWord> _savedWords = [];
  List<SavedWord> get savedWords => List.unmodifiable(_savedWords);

  Future<void> _loadSavedWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data) as List<dynamic>;
        _savedWords = decoded
            .map((e) => SavedWord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved words: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_savedWords.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving saved words: $e');
    }
  }

  bool _exists(
    String languagePairKey,
    String topic,
    String source,
    String target,
  ) {
    return _savedWords.any(
      (w) =>
          w.languagePairKey == languagePairKey &&
          w.topic == topic &&
          w.sourceWord == source &&
          w.targetWord == target,
    );
  }

  Future<void> addWord({
    required String sourceWord,
    required String targetWord,
    required String languagePairKey,
    required String topic,
  }) async {
    await ready;
    if (_exists(languagePairKey, topic, sourceWord, targetWord)) {
      return;
    }
    final id =
        '$languagePairKey|$topic|$sourceWord|$targetWord|${DateTime.now().millisecondsSinceEpoch}';
    final saved = SavedWord(
      id: id,
      sourceWord: sourceWord,
      targetWord: targetWord,
      languagePairKey: languagePairKey,
      topic: topic,
      addedAt: DateTime.now(),
    );
    _savedWords.add(saved);
    await _save();
    notifyListeners();
  }

  bool isSavedWord(VocabularyWord word) => isSavedParts(
    languagePairKey: word.languagePairKey,
    sourceWord: word.sourceWord,
    targetWord: word.targetWord,
  );

  bool isSavedParts({
    required String languagePairKey,
    required String sourceWord,
    required String targetWord,
  }) => _savedWords.any((w) =>
      w.languagePairKey == languagePairKey &&
      w.sourceWord == sourceWord && w.targetWord == targetWord);


  Future<bool> toggleWord(VocabularyWord word) async {
    await ready;
    if (isSavedWord(word)) {
      _savedWords.removeWhere((w) =>
          w.languagePairKey == word.languagePairKey &&
          w.sourceWord == word.sourceWord && w.targetWord == word.targetWord);
      await _save();
      notifyListeners();
      return false;
    }
    await addWord(
      sourceWord: word.sourceWord,
      targetWord: word.targetWord,
      languagePairKey: word.languagePairKey,
      topic: word.topic,
    );
    return true;
  }


  Future<void> removeWord(String id) async {
    _savedWords.removeWhere((w) => w.id == id);
    await _save();
    notifyListeners();
  }

  List<SavedWord> forLanguagePair(String languagePairKey) {
    return _savedWords
        .where((w) => w.languagePairKey == languagePairKey)
        .toList();
  }

  List<SavedWord> forLanguagePairAndTopic(
    String languagePairKey,
    String topicId,
  ) {
    return _savedWords
        .where(
          (w) => w.languagePairKey == languagePairKey && w.topic == topicId,
        )
        .toList();
  }
}
