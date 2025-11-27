import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;

  LocaleService._internal() {
    _loadLocale();
  }

  static const _storageKey = 'app_locale_code';

  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_storageKey);
      if (code != null && code.isNotEmpty) {
        _locale = Locale(code);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLocaleCode(String code) async {
    _locale = Locale(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, code);
    } catch (_) {}
    notifyListeners();
  }
}
