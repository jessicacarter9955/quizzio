import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/models/saved_word.dart';

class SavedWordsService extends ChangeNotifier {
  static final SavedWordsService _instance = SavedWordsService._internal();
  factory SavedWordsService() => _instance;

  SavedWordsService._internal() {
    _loadSavedWords();
  }

  static const _storageKey = 'saved_words';

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
