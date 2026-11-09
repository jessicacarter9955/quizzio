import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/models/vocabulary_word.dart';
import 'package:wordweaver/services/grammar_practice_service.dart';
import 'dart:math';
import 'package:wordweaver/services/quizlab_topics.dart';

class VocabularyService extends ChangeNotifier {
  static const int _vocabVersion = 5;
  // Singleton instance to ensure vocabulary is loaded once and shared
  static final VocabularyService _instance = VocabularyService._internal();
  factory VocabularyService() => _instance;

  late final Completer<void> _readyCompleter;
  Map<String, Map<String, List<VocabularyWord>>> _vocabulary = {};
  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;

  VocabularyService._internal() {
    _readyCompleter = Completer<void>();
    _loadVocabulary();
  }

  /// Await this before accessing data to ensure it's loaded.
  Future<void> get ready async => _readyCompleter.future;

  /// Original Quiz Lab is bundled once and materialized lazily for each
  /// Wordweaver language direction. We never write its whole multilingual
  /// corpus to SharedPreferences (browser quota / mobile memory protection).
  List<dynamic> _originalQuizLabTerms = [];
  final Map<String, int> _pairCountCache = <String, int>{};
  final Set<String> _hydratedDirections = {};

  Future<void> _loadOriginalQuizLabCorpus() async {
    try {
      final data = jsonDecode(await rootBundle.loadString(
        'assets/data/quizlab_terms.json')) as Map<String, dynamic>;
      _originalQuizLabTerms = data['terms'] as List<dynamic>? ?? [];
      // The build step already aligns the conversation JSONs with the original
      // multilingual rows. Do not append those questions again at runtime.
      _pairCountCache.clear();
      debugPrint('Original Quiz Lab: ${_originalQuizLabTerms.length} terms available.');
    } catch (e) {
      debugPrint('Original Quiz Lab vocabulary missing: $e');
    }
  }

  void _ensurePair(String languagePairKey) {
    // Wordweaver Home may ask for topic counts while assets are still loading.
    // Do not mark a direction as hydrated until the bundled corpus is ready.
    if (_originalQuizLabTerms.isEmpty) return;
    if (_hydratedDirections.contains(languagePairKey)) return;
    _hydratedDirections.add(languagePairKey);
    final codes = languagePairKey.split('_');
    if (codes.length != 2 || codes[0] == codes[1]) return;
    final languageVocab = _vocabulary.putIfAbsent(
      languagePairKey, () => <String, List<VocabularyWord>>{});
    final seen = <String>{};
    for (final words in languageVocab.values) {
      for (final w in words) {
        seen.add('${w.topic}\u0001${w.sourceWord.toLowerCase()}\u0001${w.targetWord.toLowerCase()}');
      }
    }
    for (final raw in _originalQuizLabTerms) {
      if (raw is! Map<String, dynamic>) continue;
      final t = raw['translations'];
      if (t is! Map<String, dynamic>) continue;
      final from = (t[codes[0]] ?? '').toString().trim();
      final to = (t[codes[1]] ?? '').toString().trim();
      if (from.isEmpty || to.isEmpty) continue;
      final topic = quizLabTopicId((raw['category'] ?? 'General').toString());
      if (!seen.add('${topic}\u0001${from.toLowerCase()}\u0001${to.toLowerCase()}')) continue;
      languageVocab.putIfAbsent(topic, () => <VocabularyWord>[]).add(
        VocabularyWord(
          id: raw['id'].toString(),
          sourceWord: from,
          targetWord: to,
          languagePairKey: languagePairKey,
          topic: topic,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
    }
  }

  Future<void> _loadVocabulary() async {
    await _loadOriginalQuizLabCorpus();
    try {
      final prefs = await SharedPreferences.getInstance();
      final vocabData = prefs.getString('vocabulary');
      final lastUpdatedStr = prefs.getString('vocabularyLastUpdated');
      final savedVersion = prefs.getInt('vocabularyVersion');

      if (vocabData != null && savedVersion == _vocabVersion) {
        final Map<String, dynamic> decoded =
            jsonDecode(vocabData) as Map<String, dynamic>;
        _vocabulary = {};
        decoded.forEach((langPairKey, topics) {
          _vocabulary[langPairKey] = {};
          (topics as Map<String, dynamic>).forEach((topicKey, words) {
            _vocabulary[langPairKey]![topicKey] = (words as List)
                .map((w) => VocabularyWord.fromJson(w as Map<String, dynamic>))
                .toList();
          });
        });
        if (lastUpdatedStr != null) {
          _lastUpdated = DateTime.parse(lastUpdatedStr);
        }
      } else {
        await _initializeSampleData();
      }
      notifyListeners();
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    } catch (e) {
      debugPrint('Error loading vocabulary: $e');
      await _initializeSampleData();
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    }
  }

  Future<void> _initializeSampleData() async {
    try {
      // Load bundled default JSON (fully merged all-pairs file)
      final jsonString = await rootBundle.loadString(
        'assets/data/vocabulary_merged_all_topics_merged_po.json',
      );
      final decoded = jsonDecode(jsonString);
      // Support either Map root or List of maps root
      Map<String, dynamic> merged = {};
      if (decoded is List) {
        for (final part in decoded) {
          if (part is Map<String, dynamic>) {
            for (final entry in part.entries) {
              if (merged.containsKey(entry.key) &&
                  merged[entry.key] is Map<String, dynamic> &&
                  entry.value is Map<String, dynamic>) {
                // Deep-merge topics for same language pair
                final existing = merged[entry.key] as Map<String, dynamic>;
                final incoming = entry.value as Map<String, dynamic>;
                incoming.forEach((topicKey, words) {
                  existing[topicKey] = words;
                });
              } else {
                merged[entry.key] = entry.value;
              }
            }
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        merged = decoded;
      } else {
        throw Exception(
          'Unsupported vocabulary JSON root: ${decoded.runtimeType}',
        );
      }
      await importFromJson(merged);
    } catch (e) {
      // Fallback to minimal hardcoded Spanish->English dataset if asset not found
      _vocabulary = {
        'es_en': {
          'food': [
            VocabularyWord(
              id: '1',
              sourceWord: 'Pan',
              targetWord: 'Bread',
              languagePairKey: 'es_en',
              topic: 'food',
              createdAt: DateTime.now(),
            ),
            VocabularyWord(
              id: '2',
              sourceWord: 'Agua',
              targetWord: 'Water',
              languagePairKey: 'es_en',
              topic: 'food',
              createdAt: DateTime.now(),
            ),
            VocabularyWord(
              id: '3',
              sourceWord: 'Manzana',
              targetWord: 'Apple',
              languagePairKey: 'es_en',
              topic: 'food',
              createdAt: DateTime.now(),
            ),
            VocabularyWord(
              id: '4',
              sourceWord: 'Leche',
              targetWord: 'Milk',
              languagePairKey: 'es_en',
              topic: 'food',
              createdAt: DateTime.now(),
            ),
          ],
          'family': [
            VocabularyWord(
              id: '11',
              sourceWord: 'Madre',
              targetWord: 'Mother',
              languagePairKey: 'es_en',
              topic: 'family',
              createdAt: DateTime.now(),
            ),
            VocabularyWord(
              id: '12',
              sourceWord: 'Padre',
              targetWord: 'Father',
              languagePairKey: 'es_en',
              topic: 'family',
              createdAt: DateTime.now(),
            ),
            VocabularyWord(
              id: '13',
              sourceWord: 'Hermano',
              targetWord: 'Brother',
              languagePairKey: 'es_en',
              topic: 'family',
              createdAt: DateTime.now(),
            ),
            VocabularyWord(
              id: '14',
              sourceWord: 'Hermana',
              targetWord: 'Sister',
              languagePairKey: 'es_en',
              topic: 'family',
              createdAt: DateTime.now(),
            ),
          ],
        },
      };
      _lastUpdated = DateTime.now();
      await _saveVocabulary();
      notifyListeners();
      debugPrint('Loaded fallback sample vocabulary due to asset error: $e');
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    }
  }

  Future<void> _saveVocabulary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> toSave = {};
      _vocabulary.forEach((langPairKey, topics) {
        toSave[langPairKey] = {};
        topics.forEach((topicKey, words) {
          toSave[langPairKey][topicKey] = words.map((w) => w.toJson()).toList();
        });
      });
      await prefs.setString('vocabulary', jsonEncode(toSave));
      await prefs.setInt('vocabularyVersion', _vocabVersion);
      if (_lastUpdated != null) {
        await prefs.setString(
          'vocabularyLastUpdated',
          _lastUpdated!.toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Error saving vocabulary: $e');
    }
  }

  /// Number of distinct translation pairs for the currently selected topics.
  /// This deliberately counts the actual quiz questions, not raw category rows.
  int getQuizWordCount(String languagePairKey, List<String> topicIds) {
    _ensurePair(languagePairKey);
    final pair = _vocabulary[languagePairKey];
    if (pair == null || topicIds.isEmpty) return 0;
    final keys = <String>{};
    for (final topic in topicIds) {
      for (final word in pair[topic] ?? <VocabularyWord>[]) {
        if (!GrammarPracticeService().isEligible(word)) continue;
        keys.add('${word.sourceWord.toLowerCase()}\u0001${word.targetWord.toLowerCase()}');
      }
    }
    return keys.length;
  }

  /// Exact number of distinct source→target pairs in the bundled vocabulary,
  /// including imported words. Languages without translations return zero.
  int getPairWordCount(String source, String target) {
    if (source == target) return 0;
    final direction = '${source}_${target}';
    final cached = _pairCountCache[direction];
    if (cached != null) return cached;
    final keys = <String>{};
    for (final raw in _originalQuizLabTerms) {
      if (raw is! Map<String, dynamic>) continue;
      final translations = raw['translations'];
      if (translations is! Map<String, dynamic>) continue;
      final from = (translations[source] ?? '').toString().trim();
      final to = (translations[target] ?? '').toString().trim();
      if (from.isNotEmpty && to.isNotEmpty) {
        keys.add('${from.toLowerCase()}\u0001${to.toLowerCase()}');
      }
    }
    final custom = _vocabulary[direction];
    if (custom != null) {
      for (final list in custom.values) {
        for (final word in list) {
          keys.add('${word.sourceWord.toLowerCase()}\u0001${word.targetWord.toLowerCase()}');
        }
      }
    }
    _pairCountCache[direction] = keys.length;
    return keys.length;
  }

  bool hasAvailableTarget(String source) {
    // Do not advertise a language with no valid target corpus.
    return _originalQuizLabTerms.any((raw) {
      if (raw is! Map<String, dynamic>) return false;
      final t = raw['translations'];
      if (t is! Map<String, dynamic>) return false;
      if ((t[source] ?? '').toString().trim().isEmpty) return false;
      return t.entries.any((entry) =>
          entry.key != source && entry.value.toString().trim().isNotEmpty);
    }) || _vocabulary.entries.any((entry) =>
        entry.key.startsWith('${source}_') &&
        entry.value.values.any((words) => words.isNotEmpty));
  }

  /// Returns the total number of vocabulary words for a given
  /// language pair and topic. If either the pair or topic
  /// doesn't exist, returns 0.
  int getWordCountForTopic(String languagePairKey, String topicId) {
    _ensurePair(languagePairKey);
    final langVocab = _vocabulary[languagePairKey];
    if (langVocab == null) return 0;
    final words = langVocab[topicId];
    if (words == null) return 0;
    return words.where(GrammarPracticeService().isEligible).length;
  }

  List<VocabularyWord> getWordsForQuiz(
    String languagePairKey,
    List<String> topicIds,
    int count,
  ) {
    _ensurePair(languagePairKey);
    debugPrint(
      'Getting words for language: $languagePairKey, topics: $topicIds',
    );
    final words = <VocabularyWord>[];

    if (!_vocabulary.containsKey(languagePairKey)) {
      debugPrint('Language pair not found: $languagePairKey');
      return [];
    }

    final languageVocab = _vocabulary[languagePairKey]!;
    final availableTopics = languageVocab.keys.toList();
    debugPrint('Available topics for $languagePairKey: $availableTopics');

    for (var topicId in topicIds) {
      // Try exact match first
      if (languageVocab.containsKey(topicId)) {
        words.addAll(languageVocab[topicId]!);
      } else {
        // Try case-insensitive match
        final matchingTopic = availableTopics.firstWhere(
          (t) => t.toLowerCase() == topicId.toLowerCase(),
          orElse: () => '',
        );
        if (matchingTopic.isNotEmpty) {
          words.addAll(languageVocab[matchingTopic]!);
        } else {
          debugPrint('Topic not found: $topicId in $languagePairKey');
        }
      }
    }

    debugPrint('Found ${words.length} words for quiz');
    if (words.isEmpty) {
      debugPrint('No words found for the selected topics');
      return [];
    }

    // The same expression can legitimately belong to different topics.
    // Ask each distinct translation only once in a combined quiz.
    final unique = <String, VocabularyWord>{};
    for (final w in words) {
      unique.putIfAbsent(
        '${w.sourceWord.toLowerCase()}\u0001${w.targetWord.toLowerCase()}',
        () => w,
      );
    }
    final shuffled = unique.values
        .where(GrammarPracticeService().isEligible).toList()..shuffle(Random());
    final result = shuffled.take(count).toList();
    debugPrint('Returning ${result.length} questions');
    return result;
  }

  List<String> getRandomWrongAnswers(
    String languagePairKey,
    String correctAnswer,
    int count, {
    String? topicId,
    List<String>? topicIds,
  }) {
    _ensurePair(languagePairKey);
    final langVocab = _vocabulary[languagePairKey];
    if (langVocab == null) return [];

    final candidates = <VocabularyWord>[];

    if (topicId != null) {
      final fromTopic = langVocab[topicId];
      if (fromTopic != null) {
        candidates.addAll(fromTopic);
      }
    } else if (topicIds != null && topicIds.isNotEmpty) {
      for (final id in topicIds) {
        final fromTopic = langVocab[id];
        if (fromTopic != null) {
          candidates.addAll(fromTopic);
        }
      }
    }

    // Fallback: if no candidates from the requested topics, use all topics
    if (candidates.isEmpty) {
      langVocab.forEach((_, words) {
        candidates.addAll(words);
      });
    }

    final allWords = candidates
        .where(GrammarPracticeService().isEligible)
        .map((w) => w.targetWord)
        .where((w) => w != correctAnswer)
        .toList();
    allWords.shuffle(Random());
    return allWords.take(count).toList();
  }

  Future<void> importFromJson(Map<String, dynamic> data) async {
    try {
      _pairCountCache.clear();
      _vocabulary = {};
      data.forEach((langPairKey, topics) {
        _vocabulary[langPairKey] = {};
        (topics as Map<String, dynamic>).forEach((topicKey, words) {
          _vocabulary[langPairKey]![topicKey] = (words as List).map((w) {
            return VocabularyWord(
              id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}',
              sourceWord: w['source'] as String,
              targetWord: w['target'] as String,
              languagePairKey: langPairKey,
              topic: topicKey,
              createdAt: DateTime.now(),
            );
          }).toList();
        });
      });
      _lastUpdated = DateTime.now();
      await _saveVocabulary();
      notifyListeners();
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    } catch (e) {
      debugPrint('Error importing vocabulary: $e');
      if (!_readyCompleter.isCompleted) _readyCompleter.completeError(e);
    }
  }
}

