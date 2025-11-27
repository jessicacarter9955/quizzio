import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _initialized = false;
  bool _available = false;

  bool get isAvailable => _available;

  Future<bool> ensureInitialized() async {
    if (_initialized) return _available;
    _available = await _speechToText.initialize(
      onStatus: (status) {},
      onError: (error) {},
    );
    _initialized = true;
    return _available;
  }

  Future<void> listen({
    String? localeId,
    required void Function(String text, bool isFinal) onResult,
  }) async {
    final ok = await ensureInitialized();
    if (!ok) return;
    await _speechToText.listen(
      localeId: localeId,
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
    );
  }

  Future<void> stop() async {
    if (!_initialized) return;
    await _speechToText.stop();
  }

  Future<void> cancel() async {
    if (!_initialized) return;
    await _speechToText.cancel();
  }
}
