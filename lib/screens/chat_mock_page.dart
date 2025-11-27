import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wordweaver/models/language.dart';
import 'package:wordweaver/services/language_service.dart';
import 'package:wordweaver/services/ai_chat_service.dart';
import 'package:wordweaver/services/ai_settings_service.dart';
import 'package:wordweaver/screens/puter_tutor_page.dart';
import 'package:wordweaver/screens/settings_page.dart';

class ChatMockPage extends StatefulWidget {
  const ChatMockPage({super.key});

  @override
  State<ChatMockPage> createState() => _ChatMockPageState();
}

class _ChatMockPageState extends State<ChatMockPage> {
  static const bool _debugAiLogs = true;

  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  final LanguageService _languageService = LanguageService();
  final AiChatService _aiChatService = AiChatService();
  final AiSettingsService _aiSettingsService = AiSettingsService();

  bool _isRecording = false;
  DateTime? _recordingStart;
  Language? _tutorLanguage;
  bool _isSending = false;

  // Temporary inline Puter bridge HTML. This can later be replaced by a
  // server-backed implementation that exposes a simple HTTP endpoint.
  static const String _puterHtml = '''<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Puter Inline Bridge</title>
    <script src="https://js.puter.com/v2/"></script>
  </head>
  <body>
    <script>
      window.PuterFlutterBridge = {
        send: async function(requestJson) {
          try {
            const req = typeof requestJson === 'string'
              ? JSON.parse(requestJson)
              : requestJson;
            const id = req.id;
            const kind = req.kind || 'chat';

            let content = '';
            let audioDataUrl = '';

            if (kind === 'speech2txt') {
              const source = req.source || req.audio || req.file;
              const options = {};
              if (req.model) options.model = req.model;
              if (req.language) options.language = req.language;
              if (typeof req.translate === 'boolean') options.translate = !!req.translate;

              let result;
              if (Object.keys(options).length === 0) {
                result = await puter.ai.speech2txt(source);
              } else {
                result = await puter.ai.speech2txt(source, options);
              }
              content = result && result.text ? result.text : ('' + result);
            } else if (kind === 'speech2speech') {
              const source = req.source || req.audio || req.file;
              const options = {};
              if (req.voice || req.voiceId || req.voice_id) {
                options.voice = req.voice || req.voiceId || req.voice_id;
              }
              if (req.model || req.modelId || req.model_id) {
                options.model = req.model || req.modelId || req.model_id;
              }

              const audioEl = Object.keys(options).length === 0
                ? await puter.ai.speech2speech(source)
                : await puter.ai.speech2speech(source, options);

              let src = audioEl && audioEl.src ? audioEl.src : '';
              if (src.startsWith('blob:')) {
                try {
                  const resp = await fetch(src);
                  const blob = await resp.blob();
                  src = await new Promise((resolve) => {
                    const reader = new FileReader();
                    reader.onloadend = () => resolve(reader.result);
                    reader.readAsDataURL(blob);
                  });
                } catch (e) {
                  src = '';
                }
              }

              audioDataUrl = src || '';
            } else {
              const model = req.model || 'gpt-5-nano';
              const messages = req.messages || [];

              const resp = await puter.ai.chat(messages, { model });

              try {
                if (typeof resp === 'string') {
                  content = resp;
                } else if (resp && resp.message && resp.message.content) {
                  const mc = resp.message.content;
                  if (Array.isArray(mc)) {
                    content = mc.map(p => p.text || '').join('\n');
                  } else {
                    content = String(mc);
                  }
                } else {
                  content = JSON.stringify(resp);
                }
              } catch (e) {
                content = String(resp);
              }
            }

            if (window.FlutterPuterBridge && window.FlutterPuterBridge.postMessage) {
              window.FlutterPuterBridge.postMessage(
                JSON.stringify({ id, content, audioDataUrl }),
              );
            }
          } catch (e) {
            let parsedId = null;
            try {
              const parsed = JSON.parse(requestJson);
              parsedId = parsed.id;
            } catch (_) {}

            if (window.FlutterPuterBridge && window.FlutterPuterBridge.postMessage) {
              window.FlutterPuterBridge.postMessage(
                JSON.stringify({ id: parsedId, error: String(e) }),
              );
            }
          }
        }
      };
    </script>
  </body>
</html>
''';

  WebViewController? _puterWebViewController;
  Completer<void>? _puterReadyCompleter;
  final Map<String, Completer<String>> _puterPendingRequests = {};

  Language? get _currentTutorLanguage =>
      _tutorLanguage ?? _languageService.currentLanguagePair?.targetLanguage;

  @override
  void initState() {
    super.initState();
    final pair = _languageService.currentLanguagePair;
    _tutorLanguage =
        pair?.targetLanguage ??
        _languageService.getLanguages().firstWhere(
          (l) => l.code == 'es',
          orElse: () {
            final all = _languageService.getLanguages();
            return all.isNotEmpty
                ? all.first
                : const Language(
                    code: 'es',
                    name: 'Spanish',
                    nativeName: 'Español',
                    flag: '🇪🇸',
                  );
          },
        );
    _messages.add(
      _ChatMessage(
        text: 'Hello, how can I help you?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    _controller.addListener(() {
      // Rebuild to toggle between mic and send icon based on text presence.
      setState(() {});
    });
  }

  Future<void> _playAudio(_ChatMessage message) async {
    final path = message.audioPath;
    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) return;
    try {
      await _player.stop();
      await _player.setFilePath(path);
      await _player.play();
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  void _addLogMessage(String text) {
    if (!_debugAiLogs) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          text: 'LOG: $text',
          isUser: false,
          timestamp: DateTime.now(),
          isLog: true,
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _addUserMessage(
      _ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    );
    _handleReplyForNewMessage();
  }

  Future<void> _handleSendAudio() async {
    // If already recording, stop and create a voice message.
    if (_isRecording) {
      final path = await _recorder.stop();
      final started = _recordingStart;
      setState(() {
        _isRecording = false;
        _recordingStart = null;
      });
      if (path == null) return;
      final duration = started != null
          ? DateTime.now().difference(started)
          : const Duration(seconds: 1);

      _addUserMessage(
        _ChatMessage(
          text: 'Voice message',
          isUser: true,
          isAudio: true,
          audioDuration: duration,
          audioPath: path,
          timestamp: DateTime.now(),
        ),
      );
      await _processRecordedAudio(path, duration);
      return;
    }

    // Otherwise, start recording.
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission not granted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final tempDir = Directory.systemTemp;
    final filePath =
        '${tempDir.path}/chat_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: filePath);
    setState(() {
      _isRecording = true;
      _recordingStart = DateTime.now();
    });
  }

  Future<void> _processRecordedAudio(String path, Duration duration) async {
    final tutor = _currentTutorLanguage;
    final code = tutor?.code ?? 'es';

    try {
      final file = File(path);
      if (!await file.exists()) {
        _addLogMessage('[Audio] File does not exist at $path');
        return;
      }

      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      final dataUrl = 'data:audio/m4a;base64,$b64';

      _addLogMessage(
        '[Audio] Sending STT to Puter, bytes=${bytes.length}, lang=$code',
      );

      final transcript = await _sendPuterTranscription(
        dataUrl: dataUrl,
        tutorLanguageCode: code,
      );

      if (!mounted) return;
      final trimmed = transcript.trim();
      if (trimmed.isEmpty) {
        _addLogMessage('[Audio] Empty transcription result');
        return;
      }

      _addUserMessage(
        _ChatMessage(text: trimmed, isUser: true, timestamp: DateTime.now()),
      );

      if (_aiSettingsService.usePuterBackend) {
        try {
          _addLogMessage('[Puter s2s] Requesting voice reply');
          final s2sPath = await _sendPuterSpeech2Speech(dataUrl: dataUrl);
          if (!mounted) return;
          _addUserMessage(
            _ChatMessage(
              text: 'AI voice',
              isUser: false,
              isAudio: true,
              audioDuration: duration,
              audioPath: s2sPath,
              timestamp: DateTime.now(),
            ),
          );
        } on AiChatException catch (e) {
          _addLogMessage('[Puter s2s error] ${e.message}');
        } catch (e) {
          _addLogMessage('[Puter s2s error] $e');
        }
      }

      _handleReplyForNewMessage();
    } on AiChatException catch (e) {
      if (!mounted) return;
      _addLogMessage('[Audio STT error] ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      _addLogMessage('[Audio STT error] $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to transcribe audio with Puter.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addUserMessage(_ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _handleReplyForNewMessage() {
    if (_aiSettingsService.usePuterBackend) {
      _maybeSendPuterReply();
      return;
    }

    final provider = _aiSettingsService.provider;
    if (provider == AiProvider.none) {
      _scheduleAutoReply();
      return;
    }
    _maybeSendAiReply();
  }

  List<Map<String, String>> _buildHistory() {
    return _messages
        .map(
          (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
        )
        .toList();
  }

  Future<void> _maybeSendPuterReply() async {
    if (_isSending) return;
    final tutor = _currentTutorLanguage;
    final code = tutor?.code ?? 'es';
    final name = tutor?.name ?? 'Spanish';

    setState(() {
      _isSending = true;
    });

    try {
      _addLogMessage(
        '[Puter chat] Requesting reply in $code ($name) with \\${_messages.length} messages',
      );
      final reply = await _sendPuterMessage(
        history: _buildHistory(),
        tutorLanguageCode: code,
        tutorLanguageName: name,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()),
        );
      });
      _scrollToBottom();
    } on AiChatException catch (e) {
      if (!mounted) return;
      _addLogMessage('[Puter chat error] ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      _addLogMessage('[Puter chat error] $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get AI reply.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _ensurePuterWebView() async {
    if (_puterWebViewController != null && _puterReadyCompleter != null) {
      await _puterReadyCompleter!.future;
      return;
    }

    _puterReadyCompleter = Completer<void>();

    _addLogMessage('[Puter] Creating WebView inline bridge');

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!(_puterReadyCompleter?.isCompleted ?? true)) {
              _puterReadyCompleter?.complete();
            }
            _addLogMessage('[Puter] WebView page finished loading');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterPuterBridge',
        onMessageReceived: (message) {
          _handlePuterJsMessage(message.message);
        },
      )
      ..loadHtmlString(_puterHtml);

    _puterWebViewController = controller;
    await _puterReadyCompleter!.future;
  }

  void _handlePuterJsMessage(String data) {
    try {
      _addLogMessage('[Puter] JS message: $data');
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final id = decoded['id']?.toString();
      final error = decoded['error']?.toString();
      final content = decoded['content']?.toString();
      final audioDataUrl = decoded['audioDataUrl']?.toString();

      if (id == null) {
        _addLogMessage('[Puter] Missing id in JS message');
        return;
      }
      final completer = _puterPendingRequests.remove(id);
      if (completer == null) {
        _addLogMessage('[Puter] No pending completer for id $id');
        return;
      }

      if (error != null && error.isNotEmpty) {
        _addLogMessage('[Puter] Error: $error');
        completer.completeError(AiChatException('Puter error: $error'));
      } else {
        final hasAudio = audioDataUrl != null && audioDataUrl.trim().isNotEmpty;
        final hasText = content != null && content.trim().isNotEmpty;

        if (!hasAudio && !hasText) {
          _addLogMessage('[Puter] Empty response (no audio/text)');
          completer.completeError(
            AiChatException('Puter returned an empty response.'),
          );
        } else if (hasAudio) {
          completer.complete(audioDataUrl.trim());
        } else {
          completer.complete(content!.trim());
        }
      }
    } catch (e) {
      _addLogMessage('[Puter] Failed to handle JS message: $e | raw=$data');
    }
  }

  // NOTE: This inline Puter bridge uses a hidden WebView + puter.js.
  // For a server-backed implementation later, keep this method signature
  // and replace the WebView call with an HTTP client to your own backend.
  Future<String> _sendPuterMessage({
    required List<Map<String, String>> history,
    required String tutorLanguageCode,
    required String tutorLanguageName,
  }) async {
    await _ensurePuterWebView();

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<String>();
    _puterPendingRequests[id] = completer;

    final model = _aiSettingsService.puterModel;

    final request = {
      'id': id,
      'kind': 'chat',
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a friendly $tutorLanguageName tutor (code: $tutorLanguageCode) running via Puter.ai.',
        },
        ...history,
      ],
    };

    final jsCode = 'window.PuterFlutterBridge.send(${jsonEncode(request)});';

    _addLogMessage(
      '[Puter chat] Sending id=$id, model=$model, history=${history.length}',
    );

    try {
      await _puterWebViewController!.runJavaScript(jsCode);
    } catch (e) {
      _puterPendingRequests.remove(id);
      throw AiChatException('Failed to invoke Puter: $e');
    }

    return completer.future;
  }

  Future<String> _sendPuterSpeech2Speech({required String dataUrl}) async {
    await _ensurePuterWebView();

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<String>();
    _puterPendingRequests[id] = completer;

    final request = {'id': id, 'kind': 'speech2speech', 'source': dataUrl};

    final jsCode = 'window.PuterFlutterBridge.send(${jsonEncode(request)});';

    _addLogMessage('[Puter s2s] Sending id=$id');

    try {
      await _puterWebViewController!.runJavaScript(jsCode);
    } catch (e) {
      _puterPendingRequests.remove(id);
      throw AiChatException('Failed to invoke Puter speech2speech: $e');
    }

    final resultDataUrl = await completer.future;
    if (!resultDataUrl.startsWith('data:audio')) {
      _addLogMessage('[Puter s2s] Invalid audio data URL');
      throw AiChatException('Puter speech2speech returned invalid audio data.');
    }

    final parts = resultDataUrl.split(',');
    if (parts.length != 2) {
      _addLogMessage('[Puter s2s] Malformed data URL');
      throw AiChatException('Puter speech2speech returned malformed data URL.');
    }
    final bytes = base64Decode(parts[1]);

    final tempDir = Directory.systemTemp;
    final filePath =
        '${tempDir.path}/puter_s2s_${DateTime.now().millisecondsSinceEpoch}.mp3';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return filePath;
  }

  Future<String> _sendPuterTranscription({
    required String dataUrl,
    required String tutorLanguageCode,
  }) async {
    await _ensurePuterWebView();

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<String>();
    _puterPendingRequests[id] = completer;

    final request = {
      'id': id,
      'kind': 'speech2txt',
      'source': dataUrl,
      'language': tutorLanguageCode,
    };

    final jsCode = 'window.PuterFlutterBridge.send(${jsonEncode(request)});';

    _addLogMessage(
      '[Puter STT] Sending id=$id, lang=$tutorLanguageCode, len=${dataUrl.length}',
    );

    try {
      await _puterWebViewController!.runJavaScript(jsCode);
    } catch (e) {
      _puterPendingRequests.remove(id);
      throw AiChatException('Failed to invoke Puter STT: $e');
    }

    return completer.future;
  }

  Future<void> _maybeSendAiReply() async {
    if (_isSending) return;
    final tutor = _currentTutorLanguage;
    final code = tutor?.code ?? 'es';
    final name = tutor?.name ?? 'Spanish';

    setState(() {
      _isSending = true;
    });

    try {
      _addLogMessage(
        '[Direct AI] Provider=${_aiSettingsService.provider} messages=${_messages.length}',
      );
      final reply = await _aiChatService.sendMessage(
        history: _buildHistory(),
        tutorLanguageCode: code,
        tutorLanguageName: name,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()),
        );
      });
      _scrollToBottom();
    } on AiChatException catch (e) {
      if (!mounted) return;
      _addLogMessage('[Direct AI error] ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      _addLogMessage('[Direct AI error] $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get AI reply.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scheduleAutoReply() {
    // Auto reply after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            text: '404 missing msg',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tutorLanguage = _currentTutorLanguage;
    final tutorFlag = tutorLanguage?.flag ?? '🇪🇸';
    final tutorName = tutorLanguage?.name ?? 'Spanish';

    final usePuter = _aiSettingsService.usePuterBackend;
    String backendLabel;
    if (usePuter) {
      backendLabel = 'Puter';
    } else {
      switch (_aiSettingsService.provider) {
        case AiProvider.openAi:
          backendLabel = 'Direct: OpenAI';
          break;
        case AiProvider.gemini:
          backendLabel = 'Direct: Gemini';
          break;
        case AiProvider.claudeAssembly:
          backendLabel = 'Direct: Claude';
          break;
        case AiProvider.none:
          backendLabel = 'Direct: (none)';
          break;
      }
    }

    final chatBackgroundDecoration = BoxDecoration(
      gradient: isDark
          ? null
          : const LinearGradient(
              colors: [
                Color(0xFFD0F8CE), // light green top
                Color(0xFFFDF9C4), // yellow-ish bottom
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      color: isDark ? const Color(0xFF0B141A) : null,
    );

    final inputBackgroundColor = isDark
        ? const Color(0xFF202C33)
        : Colors.white;
    const actionButtonColor = Color(0xFF00A884);
    final hasText = _controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.transparent,
              child: Text(tutorFlag, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<Language>(
              onSelected: (lang) {
                setState(() {
                  _tutorLanguage = lang;
                });
              },
              itemBuilder: (context) {
                final languages = _languageService.getLanguages();
                return languages
                    .map(
                      (lang) => PopupMenuItem<Language>(
                        value: lang,
                        child: Text('${lang.name} tutor'),
                      ),
                    )
                    .toList();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$tutorName tutor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<bool>(
            tooltip: 'AI backend',
            onSelected: (value) {
              _aiSettingsService.setUsePuterBackend(value);
              setState(() {});
            },
            itemBuilder: (context) => const [
              PopupMenuItem<bool>(
                value: true,
                child: Text('Puter (no API key)'),
              ),
              PopupMenuItem<bool>(value: false, child: Text('Direct provider')),
            ],
            child: Row(
              children: [
                const Icon(Icons.memory),
                const SizedBox(width: 4),
                Text(
                  backendLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (usePuter)
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value:
                    const [
                      'gpt-5-nano',
                      'gpt-5-nano-reasoning',
                      'gpt-4.1-mini',
                    ].contains(_aiSettingsService.puterModel)
                    ? _aiSettingsService.puterModel
                    : 'gpt-5-nano',
                items: const [
                  DropdownMenuItem(
                    value: 'gpt-5-nano',
                    child: Text('gpt-5-nano'),
                  ),
                  DropdownMenuItem(
                    value: 'gpt-5-nano-reasoning',
                    child: Text('gpt-5-nano-reasoning'),
                  ),
                  DropdownMenuItem(
                    value: 'gpt-4.1-mini',
                    child: Text('gpt-4.1-mini'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _aiSettingsService.setPuterModel(value);
                    setState(() {});
                  }
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Speech & AI settings',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AiSettingsPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud),
            tooltip: 'Open Puter AI tutor',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PuterTutorPage()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: chatBackgroundDecoration,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  if (message.isAudio) {
                    return GestureDetector(
                      onTap: () => _playAudio(message),
                      child: _ChatBubble(message: message),
                    );
                  }
                  return _ChatBubble(message: message);
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: inputBackgroundColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.insert_emoticon_outlined,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Message',
                                border: InputBorder.none,
                              ),
                              minLines: 1,
                              maxLines: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: hasText ? _handleSend : _handleSendAudio,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: _isRecording
                          ? Colors.redAccent
                          : actionButtonColor,
                      child: Icon(
                        hasText
                            ? Icons.send
                            : (_isRecording ? Icons.stop : Icons.mic),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_aiSettingsService.usePuterBackend &&
              _puterWebViewController != null)
            Offstage(
              offstage: true,
              child: SizedBox(
                height: 0,
                width: 0,
                child: WebViewWidget(controller: _puterWebViewController!),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isAudio;
  final DateTime timestamp;
  final Duration? audioDuration;
  final String? audioPath;
  final bool isLog;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isAudio = false,
    this.audioDuration,
    this.audioPath,
    this.isLog = false,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final isDark = theme.brightness == Brightness.dark;

    final isLog = message.isLog;

    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final userBubbleColor = isDark
        ? const Color(0xFF005C4B)
        : const Color(0xFFDCF8C6);
    final otherBubbleColor = isDark ? const Color(0xFF202C33) : Colors.white;
    final logBubbleColor = isDark
        ? const Color(0xFF5B1F1F)
        : const Color(0xFFFFCDD2);
    final bubbleColor = isLog
        ? logBubbleColor
        : (isUser ? userBubbleColor : otherBubbleColor);
    final textColor = isDark ? Colors.white : Colors.black87;

    Widget content;
    if (message.isAudio) {
      final duration = message.audioDuration ?? const Duration(seconds: 3);
      final minutes = duration.inMinutes;
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      final label = '$minutes:$seconds';
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
        ],
      );
    } else {
      content = Text(
        message.text,
        style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
      );
    }

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
