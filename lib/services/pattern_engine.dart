import 'package:wordweaver/models/vocabulary_word.dart';

/// Pattern groups are calculated from the active Wordweaver language pair.
enum PatternMode { prefix, suffix, letters, words }

class PatternGroup {
  const PatternGroup(this.key, this.title, this.words);
  final String key;
  final String title;
  final List<VocabularyWord> words;
}

/// No question cap: selected groups contribute all their distinct terms.
class PatternEngine {
  static String normalized(String s) => s.trim().toLowerCase()
      .replaceAll(RegExp(r'^[^\w\p{L}\p{N}]+', unicode: true), '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]+', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  static String identity(VocabularyWord w) =>
      '${w.languagePairKey}|\u0001${normalized(w.sourceWord)}|\u0001${normalized(w.targetWord)}';

  static List<VocabularyWord> distinct(Iterable<VocabularyWord> words) {
    final map = <String, VocabularyWord>{};
    for (final w in words) {
      if (w.sourceWord.trim().isEmpty || w.targetWord.trim().isEmpty) continue;
      map.putIfAbsent(identity(w), () => w);
    }
    return map.values.toList();
  }

  static String lettersOnly(String value) =>
      normalized(value).replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');

  static List<PatternGroup> group(
    Iterable<VocabularyWord> source,
    PatternMode mode, {
    String branch = '',
    int depth = 1,
  }) {
    final map = <String, List<VocabularyWord>>{};
    for (final word in distinct(source)) {
      final chars = lettersOnly(word.sourceWord).runes.toList();
      if (chars.isEmpty) continue;
      final text = String.fromCharCodes(chars);
      if (mode == PatternMode.prefix && !text.startsWith(branch)) continue;
      if (mode == PatternMode.suffix && !text.endsWith(branch)) continue;
      String key;
      switch (mode) {
        case PatternMode.prefix:
          key = text.length <= depth ? text : String.fromCharCodes(chars.take(depth));
        case PatternMode.suffix:
          key = text.length <= depth ? text : String.fromCharCodes(chars.skip(chars.length - depth));
        case PatternMode.letters:
          key = chars.length.toString();
        case PatternMode.words:
          key = normalized(word.sourceWord).split(' ').where((x) => x.isNotEmpty).length.toString();
      }
      map.putIfAbsent(key, () => []).add(word);
    }
    final entries = map.entries.toList()..sort((a, b) {
      if (mode == PatternMode.letters || mode == PatternMode.words) {
        return int.parse(a.key).compareTo(int.parse(b.key));
      }
      return a.key.compareTo(b.key);
    });
    return entries.map((e) {
      final title = switch (mode) {
        PatternMode.suffix => '…${e.key}',
        PatternMode.prefix => '${e.key}…',
        PatternMode.letters => '${e.key} letters',
        PatternMode.words => '${e.key} words',
      };
      return PatternGroup(e.key, title, e.value..sort((a, b) => a.sourceWord.compareTo(b.sourceWord)));
    }).toList();
  }

  static List<VocabularyWord> selectedWords(
    Map<String, List<VocabularyWord>> selection, {int? maximum}) {
    final all = distinct(selection.values.expand((x) => x));
    return maximum == null ? all : all.take(maximum < 1 ? 1 : maximum).toList();
  }
}
