import 'package:flutter/foundation.dart';

enum AiProvider { none, openAi, gemini, claudeAssembly }

class AiSettingsService extends ChangeNotifier {
  static final AiSettingsService _instance = AiSettingsService._internal();
  factory AiSettingsService() => _instance;

  AiSettingsService._internal();

  AiProvider _provider = AiProvider.none;
  String? _openAiApiKey;

  AiProvider get provider => _provider;
  String? get openAiApiKey => _openAiApiKey;

  void setProvider(AiProvider value) {
    if (value == _provider) return;
    _provider = value;
    notifyListeners();
  }

  void setOpenAiApiKey(String? value) {
    if (value == _openAiApiKey) return;
    _openAiApiKey = value;
    notifyListeners();
  }
}
