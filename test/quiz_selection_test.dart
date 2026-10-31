import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/services/quiz_service.dart';
import 'package:wordweaver/services/quiz_selection.dart';
import 'package:wordweaver/services/topic_service.dart';
import 'package:wordweaver/services/vocabulary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Default settings: Max questions and focus on one topic', () async {
    SharedPreferences.setMockInitialValues({});
    final quiz = QuizService();
    await quiz.setQuestionCount(0);
    await quiz.setTopicMode('single');
    expect(quiz.questionCount, 0);
    expect(quiz.topicMode, 'single');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('quizQuestionCount'), 0);
    expect(prefs.getString('quizTopicMode'), 'single');
  });

  test('Translation pairs, topics and displayed quiz counts match real words', () async {
    SharedPreferences.setMockInitialValues({});
    final vocabulary = VocabularyService();
    final topics = TopicService();
    await Future.wait([vocabulary.ready, topics.ready]);
    expect(vocabulary.getPairWordCount('en', 'es'), greaterThan(0));
    expect(vocabulary.getPairWordCount('es', 'en'), greaterThan(0));
    expect(vocabulary.getPairWordCount('en', 'en'), 0);

    final available = QuizSelection.availableTopics('en_es');
    expect(available, isNotEmpty);
    for (final topic in available) {
      final count = vocabulary.getWordCountForTopic('en_es', topic.id);
      expect(count, greaterThan(0));
    }
    final first = available.first;
    final topicIds = [first.id];
    final uniqueCount = QuizSelection.wordCount('en_es', topicIds);
    expect(uniqueCount, greaterThan(0));
    expect(QuizSelection.quizCount('en_es', topicIds), uniqueCount);
    final actual = vocabulary.getWordsForQuiz('en_es', topicIds, 0x7fffffff);
    expect(actual.length, uniqueCount);
    expect(actual.every((w) => w.topic == first.id), isTrue);
    expect(actual.every((w) => w.languagePairKey == 'en_es'), isTrue);
    expect(actual.every((w) => w.sourceWord.isNotEmpty && w.targetWord.isNotEmpty), isTrue);
  });
}
