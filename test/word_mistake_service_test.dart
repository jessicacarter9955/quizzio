import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/models/vocabulary_word.dart';
import 'package:wordweaver/screens/mistake_review_page.dart';
import 'package:wordweaver/screens/pattern_mnemonic_page.dart';
import 'package:wordweaver/services/pattern_engine.dart';
import 'package:wordweaver/services/word_mistake_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final item = VocabularyWord(
    id: 'test-bread', sourceWord: 'bread', targetWord: 'pan',
    languagePairKey: 'en_es', topic: 'food',
    createdAt: DateTime.utc(2026, 10, 31),
  );

  test('Imports old Writing mistakes once and counts modes per exact word', () async {
    SharedPreferences.setMockInitialValues({
      WordMistakeService.writingHistoryKey: jsonEncode([
        {'pair': 'en_es', 'word': 'legacy', 'source': 'bread',
         'target': 'pan', 'correct': false, 'mode': 'recall',
         'at': '2026-10-01T10:00:00.000'},
        {'pair': 'en_es', 'word': 'legacy', 'source': 'bread',
         'target': 'pan', 'correct': true, 'mode': 'copy',
         'at': '2026-10-02T10:00:00.000'},
      ]),
    });
    final service = WordMistakeService();
    await service.ready;
    expect(service.mistakenWordCount, 1);
    expect(service.mistakes.single.wrong, 1);
    expect(service.mistakes.single.correct, 1);
    expect(service.mistakes.single.wrongByMode['writing'], 1);

    await service.recordAnswer(word: item, isCorrect: false, mode: 'standard');
    expect(service.mistakenWordCount, 1);
    expect(service.totalMistakes, 2);
    expect(service.mistakes.single.wrongByMode['standard'], 1);
    expect(service.mistakes.single.topics, contains('food'));

    await service.recordAnswer(word: item, isCorrect: true, mode: 'mnemonic');
    expect(service.mistakes.single.correct, 2);
    expect(service.mistakes.single.errorRate, 0.5);

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString(WordMistakeService.storageKey)!)
        as Map<String, dynamic>;
    expect(saved['writingMigrated'], true);
    expect((saved['records'] as List).length, 1);
    expect((saved['records'] as List).single['wrong'], 2);
  });

  testWidgets('Review list shows errors and filters', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MistakeReviewPage()));
    await tester.pumpAndSettle();
    expect(find.text('Most missed words'), findsOneWidget);
    expect(find.textContaining('bread'), findsWidgets);
    expect(find.textContaining('mistakes'), findsWidgets);
    expect(find.text('Quiz (1)'), findsOneWidget);
  });

  testWidgets('Forced mnemonic review includes already mastered words', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wordweaver.mnemonic.321.v1', jsonEncode({
      PatternEngine.identity(item): {'stage': 3, 'hits': 0, 'due': null},
    }));
    await tester.pumpWidget(MaterialApp(home: PatternMnemonicPage(
      words: [item], pairKey: 'en_es', forcePractice: true,
    )));
    await tester.pumpAndSettle();
    expect(find.text('bread'), findsOneWidget);
    expect(find.text('Reveal answer'), findsOneWidget);
  });
}
