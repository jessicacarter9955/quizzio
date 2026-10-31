import 'package:flutter_test/flutter_test.dart';
import 'package:wordweaver/models/vocabulary_word.dart';
import 'package:wordweaver/services/pattern_engine.dart';

VocabularyWord word(int i, String from, String to) => VocabularyWord(
  id: 'test$i', sourceWord: from, targetWord: to,
  languagePairKey: 'en_es', topic: 'test',
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  test('selected pattern groups do not cap questions at 50', () {
    final words = List.generate(125, (i) => word(i, 'word$i', 'palabra$i'));
    final chosen = PatternEngine.selectedWords({'a': words.take(80).toList(),
      'b': words.skip(40).toList()});
    expect(chosen.length, 125);
    expect(PatternEngine.selectedWords({'a': words}, maximum: 73).length, 73);
  });

  test('same word in overlapping prefix groups is not counted twice', () {
    final w = word(1, 'apple', 'manzana');
    final selected = PatternEngine.selectedWords({'a': [w], 'ap': [w]});
    expect(selected.length, 1);
  });

  test('translations with same source spelling are distinct', () {
    final a = word(1, 'bank', 'banco');
    final b = word(2, 'bank', 'orilla');
    expect(PatternEngine.distinct([a, b]).length, 2);
  });

  test('prefix/suffix drill-down partitions words', () {
    final words = [word(1, 'casa', 'house'),
      word(2, 'cane', 'dog'), word(3, 'canto', 'song')];
    final first = PatternEngine.group(words, PatternMode.prefix);
    expect(first.single.key, 'c');
    final second = PatternEngine.group(words, PatternMode.prefix, branch: 'c', depth: 2);
    expect(second.single.key, 'ca');
    final suffix = PatternEngine.group(words, PatternMode.suffix);
    expect(suffix.map((e) => e.key).toSet(), {'a', 'e', 'o'});
  });

  test('Unicode letters are not stripped from pattern keys', () {
    final groups = PatternEngine.group(
      [word(1, '你好', 'hello'), word(2, '日本語', 'Japanese')],
      PatternMode.prefix);
    expect(groups.length, 2);
  });
}
