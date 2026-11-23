import 'package:flutter_test/flutter_test.dart';
import 'package:wordweaver/models/vocabulary_word.dart';
import 'package:wordweaver/services/pattern_engine.dart';
import 'package:wordweaver/services/word_difficulty_service.dart';

void main() {
  test('difficulty identity matches PatternEngine identity', () {
    final word = VocabularyWord(
      id: '1',
      sourceWord: ' café ',
      targetWord: 'coffee shop',
      languagePairKey: 'fr_en',
      topic: 'test',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    expect(
      WordDifficultyService.identityForParts(
        languagePairKey: word.languagePairKey,
        sourceWord: word.sourceWord,
        targetWord: word.targetWord,
      ),
      PatternEngine.identity(word),
    );
  });
}
