import 'package:wordweaver/models/topic.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/quiz_service.dart';
import 'package:wordweaver/services/vocabulary_service.dart';

/// One source of truth for Home, quiz modes, Patterns and Settings.
/// A topic or language direction without matching translations is not playable.
class QuizSelection {
  static List<Topic> availableTopics(String? pairKey) {
    if (pairKey == null) return [];
    final vocabulary = VocabularyService();
    return TopicService().topics.where(
      (topic) => vocabulary.getWordCountForTopic(pairKey, topic.id) > 0,
    ).toList();
  }

  static List<Topic> activeTopics(
    String? pairKey, {
    bool? focusOnOne,
  }) {
    final available = availableTopics(pairKey);
    final selected = TopicService().getSelectedTopics().map((t) => t.id).toSet();
    final filtered = selected.isEmpty
        ? available
        : available.where((t) => selected.contains(t.id)).toList();
    final single = focusOnOne ?? QuizService().topicMode == 'single';
    return single ? filtered.take(1).toList() : filtered;
  }

  static int wordCount(String? pairKey, Iterable<String> topicIds) {
    if (pairKey == null) return 0;
    return VocabularyService().getQuizWordCount(pairKey, topicIds.toList());
  }

  static int quizCount(String? pairKey, Iterable<String> topicIds) {
    final available = wordCount(pairKey, topicIds);
    final limit = QuizService().questionCount;
    return limit <= 0 ? available : (limit < available ? limit : available);
  }
}
