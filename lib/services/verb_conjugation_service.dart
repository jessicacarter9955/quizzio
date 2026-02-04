import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ConjugationEntry {
  final String subjectSource;
  final String subjectTarget;
  final String verbSource;
  final String verbTarget;

  const ConjugationEntry({
    required this.subjectSource,
    required this.subjectTarget,
    required this.verbSource,
    required this.verbTarget,
  });
}

class VerbConjugationService {
  static final VerbConjugationService _instance =
      VerbConjugationService._internal();
  factory VerbConjugationService() => _instance;

  VerbConjugationService._internal();

  bool _loaded = false;
  late Map<String, dynamic> _data;

  Future<void> _load() async {
    if (_loaded) return;
    final jsonString = await rootBundle.loadString(
      'assets/data/verb_conjugations.json',
    );
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Unsupported verb conjugations JSON root: ${decoded.runtimeType}',
      );
    }
    _data = decoded;
    _loaded = true;
  }

  Future<void> ensureLoaded() => _load();

  List<String> getAvailableTenses(String languagePairKey) {
    if (!_loaded) return [];
    final pair = _data[languagePairKey];
    if (pair is! Map<String, dynamic>) return [];
    final tenses = pair['tenses'];
    if (tenses is! Map<String, dynamic>) return [];
    return tenses.keys.cast<String>().toList();
  }

  String? getTenseDisplayName(String languagePairKey, String tenseId) {
    if (!_loaded) return null;
    final pair = _data[languagePairKey];
    if (pair is! Map<String, dynamic>) return null;
    final tenses = pair['tenses'];
    if (tenses is! Map<String, dynamic>) return null;
    final tense = tenses[tenseId];
    if (tense is! Map<String, dynamic>) return null;
    return tense['name']?.toString();
  }

  List<String> getAvailableVerbs(String languagePairKey, String tenseId) {
    if (!_loaded) return [];
    final pair = _data[languagePairKey];
    if (pair is! Map<String, dynamic>) return [];
    final tenses = pair['tenses'];
    if (tenses is! Map<String, dynamic>) return [];
    final tense = tenses[tenseId];
    if (tense is! Map<String, dynamic>) return [];
    final verbs = tense['verbs'];
    if (verbs is! Map<String, dynamic>) return [];
    return verbs.keys.cast<String>().toList();
  }

  List<ConjugationEntry> getConjugations(
    String languagePairKey,
    String tenseId,
    String verbKey,
  ) {
    if (!_loaded) return [];
    final pair = _data[languagePairKey];
    if (pair is! Map<String, dynamic>) return [];
    final tenses = pair['tenses'];
    if (tenses is! Map<String, dynamic>) return [];
    final tense = tenses[tenseId];
    if (tense is! Map<String, dynamic>) return [];
    final verbs = tense['verbs'];
    if (verbs is! Map<String, dynamic>) return [];
    final verb = verbs[verbKey];
    if (verb is! Map<String, dynamic>) return [];
    final persons = verb['persons'];
    if (persons is! List) return [];
    final result = <ConjugationEntry>[];
    for (final p in persons) {
      if (p is! Map<String, dynamic>) continue;
      final subjectSource = p['subjectSource']?.toString();
      final subjectTarget = p['subjectTarget']?.toString();
      final verbSource = p['verbSource']?.toString();
      final verbTarget = p['verbTarget']?.toString();
      if (subjectSource == null ||
          subjectTarget == null ||
          verbSource == null ||
          verbTarget == null) {
        continue;
      }
      result.add(
        ConjugationEntry(
          subjectSource: subjectSource,
          subjectTarget: subjectTarget,
          verbSource: verbSource,
          verbTarget: verbTarget,
        ),
      );
    }
    return result;
  }
}
