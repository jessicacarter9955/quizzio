import 'language.dart';

class LanguagePair {
  final Language source;
  final Language target;

  const LanguagePair({required this.source, required this.target});

  String get key => '${source.code}_${target.code}';

  Language get sourceLanguage => source;
  Language get targetLanguage => target;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguagePair &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          target == other.target;

  @override
  int get hashCode => source.hashCode ^ target.hashCode;

  @override
  String toString() => 'LanguagePair($source -> $target)';
}
