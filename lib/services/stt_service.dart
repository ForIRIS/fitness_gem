import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// STTService - Speech To Text service for voice input
class STTService {
  static final STTService _instance = STTService._internal();
  factory STTService() => _instance;
  STTService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  /// Initialize STT
  Future<bool> initialize() async {
    if (_isAvailable) return true;

    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
          }
        },
        onError: (errorNotification) {
          debugPrint('STT Error: $errorNotification');
          _isListening = false;
        },
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('STT Initialization Error: $e');
      return false;
    }
  }

  /// Start Listening
  Future<void> startListening({
    required Function(String) onResult,
    String? languageCode,
  }) async {
    if (!_isAvailable) {
      final init = await initialize();
      if (!init) return;
    }

    if (_isListening) return;

    _isListening = true;
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      localeId: languageCode ?? 'en-US',
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  /// Stop Listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
  }

  /// Cancel Listening
  Future<void> cancelListening() async {
    await _speech.cancel();
    _isListening = false;
  }
}
