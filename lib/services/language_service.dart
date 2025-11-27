import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';
import '../models/language_pair.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  LanguagePair? _currentPair;
  LanguagePair? get currentPair => _currentPair;
  LanguagePair? get currentLanguagePair => _currentPair;

  Language get sourceLanguage =>
      _currentPair?.source ?? Language.supported.first;
  Language get targetLanguage => _currentPair?.target ?? Language.supported[1];

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final sourceCode = prefs.getString('sourceLanguage') ?? 'en';
    final targetCode = prefs.getString('targetLanguage') ?? 'es';

    final source = Language.supported.firstWhere(
      (lang) => lang.code == sourceCode,
    );
    final target = Language.supported.firstWhere(
      (lang) => lang.code == targetCode,
    );

    _currentPair = LanguagePair(source: source, target: target);
    notifyListeners();
  }

  Future<void> setLanguagePair(Language source, Language target) async {
    _currentPair = LanguagePair(source: source, target: target);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sourceLanguage', source.code);
    await prefs.setString('targetLanguage', target.code);
    notifyListeners();
  }

  List<Language> searchLanguages(String query) {
    if (query.isEmpty) return Language.supported;
    final lowerQuery = query.toLowerCase();
    return Language.supported
        .where(
          (lang) =>
              lang.name.toLowerCase().contains(lowerQuery) ||
              lang.nativeName.toLowerCase().contains(lowerQuery) ||
              lang.code.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  List<Language> getAvailableTargets(Language source) {
    return Language.supported
        .where((lang) => lang.code != source.code)
        .toList();
  }

  List<Language> getLanguages() => Language.supported;

  String get currentLanguagePairKey => _currentPair?.key ?? 'en_es';
}
