import 'package:flutter/foundation.dart';

enum AiProvider { none, openAi, gemini, claudeAssembly, proxyServer }

class AiSettingsService extends ChangeNotifier {
  static final AiSettingsService _instance = AiSettingsService._internal();
  factory AiSettingsService() => _instance;

  AiSettingsService._internal();

  bool _usePuterBackend = true;
  String _puterModel = 'gpt-5-nano';
  String? _puterBridgeUrl;

  AiProvider _provider = AiProvider.openAi;
  String? _openAiApiKey;
  String? _geminiApiKey;
  String? _claudeAssemblyApiKey;
  String? _proxyBaseUrl;

  bool get usePuterBackend => _usePuterBackend;
  String get puterModel => _puterModel;
  String? get puterBridgeUrl => _puterBridgeUrl;

  AiProvider get provider => _provider;
  String? get openAiApiKey => _openAiApiKey;
  String? get geminiApiKey => _geminiApiKey;
  String? get claudeAssemblyApiKey => _claudeAssemblyApiKey;
  String? get proxyBaseUrl => _proxyBaseUrl;

  void setUsePuterBackend(bool value) {
    if (value == _usePuterBackend) return;
    _usePuterBackend = value;
    notifyListeners();
  }

  void setPuterModel(String value) {
    if (value == _puterModel) return;
    _puterModel = value;
    notifyListeners();
  }

  void setPuterBridgeUrl(String? value) {
    if (value == _puterBridgeUrl) return;
    _puterBridgeUrl = value;
    notifyListeners();
  }

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

  void setGeminiApiKey(String? value) {
    if (value == _geminiApiKey) return;
    _geminiApiKey = value;
    notifyListeners();
  }

  void setClaudeAssemblyApiKey(String? value) {
    if (value == _claudeAssemblyApiKey) return;
    _claudeAssemblyApiKey = value;
    notifyListeners();
  }

  void setProxyBaseUrl(String? value) {
    if (value == _proxyBaseUrl) return;
    _proxyBaseUrl = value;
    notifyListeners();
  }
}
