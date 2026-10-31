import 'package:wordweaver/models/vocabulary_word.dart';
import 'package:wordweaver/services/pattern_engine.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/vocabulary_service.dart';

/// The exact same source→target corpus and taxonomy as the Home quiz.
/// No second quiz importer, no unmatched demo-only topics.
class PatternCatalog {
  static Future<List<VocabularyWord>> forPair(
    String languagePairKey, {
    List<String>? topicIds,
  }) async {
    final vocabulary = VocabularyService();
    final topics = TopicService();
    await Future.wait([vocabulary.ready, topics.ready]);
    final ids = topicIds ?? topics.topics.map((t) => t.id).toList();
    return PatternEngine.distinct(vocabulary.getWordsForQuiz(
      languagePairKey,
      ids,
      0x7fffffff,
    ));
  }
}
