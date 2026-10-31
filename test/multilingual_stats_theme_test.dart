import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/main.dart';
import 'package:wordweaver/screens/stats_page.dart';
import 'package:wordweaver/services/quiz_service.dart';
import 'package:wordweaver/services/stats_service.dart';
import 'package:wordweaver/services/user_service.dart';
import 'package:wordweaver/services/vocabulary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('German/French and Spanish/Russian directions share verified rows', () async {
    SharedPreferences.setMockInitialValues({});
    final vocabulary = VocabularyService();
    await vocabulary.ready;
    expect(vocabulary.getPairWordCount('de', 'fr'), greaterThan(1000));
    expect(vocabulary.getPairWordCount('fr', 'de'), greaterThan(1000));
    expect(vocabulary.getPairWordCount('es', 'ru'), greaterThan(10));
    expect(vocabulary.getPairWordCount('ru', 'es'), greaterThan(10));
    expect(vocabulary.getPairWordCount('pt', 'de'), greaterThan(0));
    expect(vocabulary.getPairWordCount('de', 'pt'), greaterThan(0));
  });

  testWidgets('Stats cards reflect answered questions without a completed quiz',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final stats = StatsService();
    await stats.ready;
    await stats.reset();
    await stats.recordAnswer(
        isCorrect: true, topicId: 'body', languagePairKey: 'de_fr');
    await stats.recordAnswer(
        isCorrect: false, topicId: 'body', languagePairKey: 'de_fr');
    expect(stats.stats.totalQuestions, 2);
    expect(stats.stats.correct, 1);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 440,
          child: QuickStatsSection(
            userService: UserService(), statsService: stats),
        ),
      ),
    ));
    expect(find.text('Total questions'), findsOneWidget);
    expect(find.text('Correct answers'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    await stats.recordQuizEnd(
        totalQuestionsInQuiz: 2, duration: const Duration(seconds: 10));
    expect(stats.stats.totalQuizzes, 1);
    expect(stats.stats.avgTimePerQuestionSec, 5.0);
  });

  testWidgets('Lime is the primary color in light and dark themes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WordweaverApp());
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.colorScheme.primary, const Color(0xFFA3E635));
    expect(app.darkTheme!.colorScheme.primary, const Color(0xFFA3E635));
    expect(app.theme!.colorScheme.onPrimary, const Color(0xFF1B2909));
  });
}
