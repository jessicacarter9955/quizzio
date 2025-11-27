import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

class ChatMockPage extends StatefulWidget {
  const ChatMockPage({super.key});

  @override
  State<ChatMockPage> createState() => _ChatMockPageState();
}

class _ChatMockPageState extends State<ChatMockPage> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  DateTime? _recordingStart;

  @override
  void initState() {
    super.initState();
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

  void _addUserMessage(_ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
    _scheduleAutoReply();
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
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.transparent,
              child: Text('🇪🇸', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 8),
            Text(
              'Spanish tutor',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isAudio = false,
    this.audioDuration,
    this.audioPath,
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

    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final userBubbleColor = isDark
        ? const Color(0xFF005C4B)
        : const Color(0xFFDCF8C6);
    final otherBubbleColor = isDark ? const Color(0xFF202C33) : Colors.white;
    final bubbleColor = isUser ? userBubbleColor : otherBubbleColor;
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
