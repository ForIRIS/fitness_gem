import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceCommandService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;

  // Callbacks
  Function()? onStart;
  Function()? onPause;
  Function()? onResume;
  Function()? onStop;

  Future<void> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) => debugPrint('STT Error: $val'),
        onStatus: (val) => debugPrint('STT Status: $val'),
      );
    } catch (e) {
      debugPrint('STT Init Failed: $e');
    }
  }

  void startListening() {
    if (!_isAvailable || _isListening) return;

    _speech.listen(
      onResult: (val) {
        if (val.recognizedWords.isNotEmpty) {
          _processCommand(val.recognizedWords);
        }
      },
      localeId: 'ko_KR', // Default to Korean
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      onSoundLevelChange: (level) {},
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
    _isListening = true;
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
  }

  void _processCommand(String text) {
    debugPrint("Voice Command Processed: $text");
    final lower = text.toLowerCase();

    if (lower.contains('start') ||
        lower.contains('시작') ||
        lower.contains('고')) {
      onStart?.call();
    } else if (lower.contains('pause') ||
        lower.contains('잠깐') ||
        lower.contains('멈춰') ||
        lower.contains('정지')) {
      onPause?.call();
    } else if (lower.contains('resume') ||
        lower.contains('계속') ||
        lower.contains('다시') ||
        lower.contains('재개')) {
      onResume?.call();
    } else if (lower.contains('quit') ||
        lower.contains('그만') ||
        lower.contains('종료') ||
        lower.contains('끝')) {
      onStop?.call();
    }
  }

  void dispose() {
    _speech.cancel();
  }
}
