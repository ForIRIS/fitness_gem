import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import '../l10n/app_localizations.dart';

/// TTSService - TTS voice feedback service
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;
  AppLocalizations? _l10n;

  /// Update localizations for TTS
  void updateLocalizations(AppLocalizations l10n) {
    _l10n = l10n;
  }

  /// Initialize TTS
  Future<void> initialize() async {
    if (_initialized) return;

    // Set English as default
    await _flutterTts.setLanguage('en-US');

    // iOS audio category configuration (mix with other audio)
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    if (!kIsWeb && isIOS) {
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }

    // Set speech rate and pitch
    await _flutterTts.setSpeechRate(0.5); // 0.0 ~ 1.0 (default 0.5)
    await _flutterTts.setPitch(1.0); // 0.5 ~ 2.0 (default 1.0)
    await _flutterTts.setVolume(1.0); // 0.0 ~ 1.0

    _initialized = true;
  }

  /// Read text aloud
  Future<void> speak(String text) async {
    if (!_initialized) {
      await initialize();
    }

    if (text.isEmpty) return;

    // Stop current speech before starting new one
    await stop();

    await _flutterTts.speak(text);
  }

  /// Stop speech playback
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Pause speech playback
  Future<void> pause() async {
    await _flutterTts.pause();
  }

  /// Check if currently speaking
  Future<bool> get isSpeaking async {
    return await _flutterTts.awaitSpeakCompletion(false);
  }

  /// Set speech rate (0.0 ~ 1.0)
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  /// Set volume (0.0 ~ 1.0)
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  /// Set completion handler
  void setCompletionHandler(Function callback) {
    _flutterTts.setCompletionHandler(() {
      callback();
    });
  }

  /// Set start handler
  void setStartHandler(Function callback) {
    _flutterTts.setStartHandler(() {
      callback();
    });
  }

  /// Set error handler
  void setErrorHandler(Function(String) callback) {
    _flutterTts.setErrorHandler((error) {
      callback(error.toString());
    });
  }

  /// Dispose TTS resources
  Future<void> dispose() async {
    await _flutterTts.stop();
  }

  // ============ Predefined Messages ============

  /// Announcement for starting workout
  Future<void> speakWorkoutStart(String exerciseName) async {
    await speak(
      _l10n?.ttsWorkoutStart(exerciseName) ??
          'Starting $exerciseName workout. Please take your position.',
    );
  }

  /// Announcement for starting a set
  Future<void> speakSetStart(int setNumber, int totalSets) async {
    await speak(_l10n?.ttsSetStart(setNumber) ?? 'Starting set $setNumber.');
  }

  /// Announcement for rest period
  Future<void> speakRestStart(int seconds) async {
    await speak(_l10n?.ttsRestStart(seconds) ?? 'Rest for $seconds seconds.');
  }

  /// Requesting ready pose
  Future<void> speakReadyPose() async {
    await speak(_l10n?.ttsReadyPose ?? 'Please take the ready pose.');
  }

  /// Announcement for workout completion
  Future<void> speakWorkoutComplete() async {
    await speak(_l10n?.ttsWorkoutComplete ?? 'Workout complete. Great job!');
  }

  /// Announcement for fall detection
  Future<void> speakFallDetection() async {
    await speak(
      _l10n?.ttsFallDetection ??
          'Are you okay? If there is no problem, please touch the screen.',
    );
  }

  /// Announcement for analysis in progress
  Future<void> speakAnalyzing() async {
    await speak(_l10n?.ttsAnalyzing ?? 'Analyzing. Please wait a moment.');
  }

  /// Real-time form correction feedback (short phrases)
  /// [message]: Short correction message in English
  Future<void> speakFormCorrection(String message) async {
    if (!_initialized) await initialize();
    if (message.isEmpty) return;

    // Faster speech rate for short, real-time corrections
    await _flutterTts.setSpeechRate(0.6);
    await _flutterTts.speak(message);
    await _flutterTts.setSpeechRate(0.5); // Restore original rate
  }

  /// Change language setting
  Future<void> setLanguage(String languageCode) async {
    // 'en' or 'ko'
    if (languageCode == 'en') {
      await _flutterTts.setLanguage('en-US');
    } else {
      await _flutterTts.setLanguage('ko-KR');
    }
  }

  /// Announcement when body is not fully visible to the camera
  Future<void> speakBodyNotVisible() async {
    await speak(
      _l10n?.ttsBodyNotVisible ??
          'Please adjust the camera so your whole body is visible.',
    );
  }

  /// Countdown announcement
  Future<void> speakCountdown(int seconds) async {
    if (seconds > 0) {
      await speak(_l10n?.ttsCountdown(seconds) ?? '$seconds');
    } else {
      await speak(_l10n?.ttsStart ?? 'Start!');
    }
  }

  /// Announcement when ready
  Future<void> speakReady() async {
    await speak(_l10n?.ttsReady ?? 'Ready! Starting soon.');
  }
}
