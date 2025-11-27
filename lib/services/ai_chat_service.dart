import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wordweaver/services/ai_settings_service.dart';

class AiChatException implements Exception {
  final String message;
  AiChatException(this.message);

  @override
  String toString() => 'AiChatException: $message';
}

class AiChatService {
  static final AiChatService _instance = AiChatService._internal();
  factory AiChatService() => _instance;

  AiChatService._internal();

  final AiSettingsService _settings = AiSettingsService();

  Future<String> sendMessage({
    required List<Map<String, String>> history,
    required String tutorLanguageCode,
    required String tutorLanguageName,
  }) async {
    final provider = _settings.provider;
    switch (provider) {
      case AiProvider.openAi:
        final key = _settings.openAiApiKey;
        if (key == null || key.isEmpty) {
          throw AiChatException(
            'OpenAI API key is not set. Add it in Settings 	 Speech & AI.',
          );
        }
        return _sendToOpenAi(
          apiKey: key,
          history: history,
          tutorLanguageCode: tutorLanguageCode,
          tutorLanguageName: tutorLanguageName,
        );
      case AiProvider.none:
        throw AiChatException(
          'AI is not enabled. Select a provider in Settings 	 Speech & AI.',
        );
      case AiProvider.gemini:
      case AiProvider.claudeAssembly:
        throw AiChatException(
          'This AI provider is not wired yet. For now, use OpenAI in Settings 	 Speech & AI.',
        );
    }
  }

  Future<String> _sendToOpenAi({
    required String apiKey,
    required List<Map<String, String>> history,
    required String tutorLanguageCode,
    required String tutorLanguageName,
  }) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            'You are a friendly $tutorLanguageName language tutor. Chat naturally in $tutorLanguageName, correct mistakes gently, and use short explanations in English when helpful.',
      },
      ...history,
    ];

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': messages,
      'temperature': 0.7,
    });

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw AiChatException('AI request failed (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw AiChatException('AI returned an empty response.');
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content']?.toString();
    if (content == null || content.trim().isEmpty) {
      throw AiChatException('AI returned an empty response.');
    }
    return content.trim();
  }
}
