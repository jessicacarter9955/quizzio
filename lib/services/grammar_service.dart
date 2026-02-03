import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class GrammarSentence {
  final String sourceSentence;
  final String targetSentence;

  GrammarSentence({required this.sourceSentence, required this.targetSentence});
}

class GrammarService {
  static final GrammarService _instance = GrammarService._internal();
  factory GrammarService() => _instance;

  GrammarService._internal();

  bool _loaded = false;
  late List<dynamic> _languagePairs;
  late Map<String, dynamic> _syntaxProfiles;
  late List<dynamic> _topics;

  Future<void> _load() async {
    if (_loaded) return;
    final jsonString = await rootBundle.loadString(
      'assets/data/grammar_profiles_mock.json',
    );
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unsupported grammar JSON root: ${decoded.runtimeType}');
    }
    _languagePairs = List<dynamic>.from(decoded['languagePairs'] as List);
    _syntaxProfiles = Map<String, dynamic>.from(
      decoded['syntaxProfiles'] as Map<String, dynamic>,
    );
    _topics = List<dynamic>.from(decoded['topics'] as List);
    _loaded = true;
  }

  Future<void> ensureLoaded() => _load();

  Map<String, String>? getLanguagePairDisplay(String key) {
    if (!_loaded) return null;
    final pairs = _languagePairs.cast<Map<String, dynamic>>();
    final match = pairs.firstWhere((p) => p['key'] == key, orElse: () => {});
    if (match.isEmpty) return null;
    final sourceLanguage = match['sourceLanguage'] as String?;
    final targetLanguage = match['targetLanguage'] as String?;
    if (sourceLanguage == null || targetLanguage == null) return null;
    return {'sourceLanguage': sourceLanguage, 'targetLanguage': targetLanguage};
  }

  Future<List<GrammarSentence>> generateSentencesForPair(
    String languagePairKey, {
    int maxSentences = 200,
  }) async {
    await ensureLoaded();

    final languagePairs = _languagePairs.cast<Map<String, dynamic>>();
    final pair = languagePairs.firstWhere(
      (p) => p['key'] == languagePairKey,
      orElse: () => {},
    );
    if (pair.isEmpty) return [];

    final syntaxProfileId = pair['syntaxProfile'] as String?;
    if (syntaxProfileId == null) return [];

    final profile = _syntaxProfiles[syntaxProfileId];
    if (profile is! List) return [];
    final topicIds = profile.map((e) => e.toString()).toList(growable: false);

    final topicMap = <String, Map<String, dynamic>>{};
    for (final raw in _topics.cast<Map<String, dynamic>>()) {
      final id = raw['id'] as String?;
      if (id != null) {
        topicMap[id] = raw;
      }
    }

    final wheels = <List<Map<String, String>>>[];
    for (final topicId in topicIds) {
      final topic = topicMap[topicId];
      if (topic == null) return [];
      final words = topic['words'];
      if (words is! List) return [];
      final filtered = <Map<String, String>>[];
      for (final w in words) {
        if (w is Map<String, dynamic> &&
            w['languagePairKey'] == languagePairKey) {
          final source = w['source']?.toString();
          final target = w['target']?.toString();
          if (source != null && target != null) {
            filtered.add({'source': source, 'target': target});
          }
        }
      }
      if (filtered.isEmpty) {
        return [];
      }
      wheels.add(filtered);
    }

    final sentences = <GrammarSentence>[];
    if (wheels.isEmpty) return sentences;

    final indices = List<int>.filled(wheels.length, 0);
    var done = false;

    while (!done && sentences.length < maxSentences) {
      final sourceParts = <String>[];
      final targetParts = <String>[];
      for (var i = 0; i < wheels.length; i++) {
        final entry = wheels[i][indices[i]];
        sourceParts.add(entry['source']!);
        targetParts.add(entry['target']!);
      }
      sentences.add(
        GrammarSentence(
          sourceSentence: sourceParts.join(' '),
          targetSentence: targetParts.join(' '),
        ),
      );

      for (var pos = wheels.length - 1; pos >= 0; pos--) {
        indices[pos]++;
        if (indices[pos] < wheels[pos].length) {
          break;
        } else {
          indices[pos] = 0;
          if (pos == 0) {
            done = true;
          }
        }
      }
    }

    return sentences;
  }
}
