import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:wordweaver/models/vocabulary_word.dart';
import 'package:wordweaver/services/vocabulary_service.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/pattern_engine.dart';

/// Supplements Wordweaver's own stored vocabulary with the existing Quiz Lab
/// bilingual quiz files. No network connection or manual import is required.
class PatternCatalog {
  static const _pairs = ['es', 'fr', 'it', 'pt', 'ru', 'ar'];

  static Future<List<VocabularyWord>> forPair(String pairKey) async {
    final source = pairKey.split('_');
    if (source.length != 2) return [];
    await VocabularyService().ready;
    final topics = TopicService().topics.map((t) => t.id).toList();
    final result = VocabularyService().getWordsForQuiz(
      pairKey, topics, 10000000,
    );
    final en = source[0] == 'en';
    final reverse = source[1] == 'en';
    final other = en ? source[1] : (reverse ? source[0] : '');
    if (_pairs.contains(other)) {
      final paths = other == 'it'
          ? ['assets/data/quiz_en_it_v2.json', 'assets/data/quiz_en_it.json']
          : ['assets/data/quiz_en_$other.json'];
      for (final path in paths) {
        try {
          final raw = jsonDecode(await rootBundle.loadString(path));
          final rows = (raw['questions'] as List<dynamic>? ?? []);
          for (var i = 0; i < rows.length; i++) {
            final item = rows[i] as Map<String, dynamic>;
            final left = (item['sourceEnglish'] ?? '').toString().trim();
            final right = (item['correctAnswer'] ?? '').toString().trim();
            if (left.isEmpty || right.isEmpty) continue;
            result.add(VocabularyWord(
              id: 'quizlab:$other:${item['id'] ?? i}',
              sourceWord: reverse ? right : left,
              targetWord: reverse ? left : right,
              languagePairKey: pairKey,
              topic: 'conversation',
              createdAt: DateTime.utc(2026, 1, 1),
            ));
          }
        } catch (_) {
          // Other pair imports remain available even if one file is missing.
        }
      }
    }
    return PatternEngine.distinct(result);
  }
}
