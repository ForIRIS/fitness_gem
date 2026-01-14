import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';

/// TTSService - TTS 음성 피드백 서비스
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;

  /// TTS 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    // 한국어 설정
    await _flutterTts.setLanguage('ko-KR');

    // iOS 오디오 카테고리 설정 (다른 오디오와 혼합)
    if (Platform.isIOS) {
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

    // 음성 속도 및 피치 설정
    await _flutterTts.setSpeechRate(0.5); // 0.0 ~ 1.0 (기본 0.5)
    await _flutterTts.setPitch(1.0); // 0.5 ~ 2.0 (기본 1.0)
    await _flutterTts.setVolume(1.0); // 0.0 ~ 1.0

    _initialized = true;
  }

  /// 텍스트를 음성으로 읽기
  Future<void> speak(String text) async {
    if (!_initialized) {
      await initialize();
    }

    if (text.isEmpty) return;

    // 현재 재생 중인 음성 중지
    await stop();

    await _flutterTts.speak(text);
  }

  /// 음성 재생 중지
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// 음성 재생 일시정지
  Future<void> pause() async {
    await _flutterTts.pause();
  }

  /// 현재 재생 중인지 확인
  Future<bool> get isSpeaking async {
    return await _flutterTts.awaitSpeakCompletion(false);
  }

  /// 음성 속도 설정 (0.0 ~ 1.0)
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  /// 볼륨 설정 (0.0 ~ 1.0)
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  /// 완료 콜백 설정
  void setCompletionHandler(Function callback) {
    _flutterTts.setCompletionHandler(() {
      callback();
    });
  }

  /// 시작 콜백 설정
  void setStartHandler(Function callback) {
    _flutterTts.setStartHandler(() {
      callback();
    });
  }

  /// 에러 콜백 설정
  void setErrorHandler(Function(String) callback) {
    _flutterTts.setErrorHandler((error) {
      callback(error.toString());
    });
  }

  /// TTS 해제
  Future<void> dispose() async {
    await _flutterTts.stop();
  }

  // ============ 미리 정의된 메시지 ============

  /// 운동 시작 안내
  Future<void> speakWorkoutStart(String exerciseName) async {
    await speak('$exerciseName 운동을 시작합니다. 자세를 취해주세요.');
  }

  /// 세트 시작 안내
  Future<void> speakSetStart(int setNumber, int totalSets) async {
    await speak('$setNumber세트를 시작합니다.');
  }

  /// 휴식 안내
  Future<void> speakRestStart(int seconds) async {
    await speak('$seconds초간 휴식하세요.');
  }

  /// 자세 준비 요청
  Future<void> speakReadyPose() async {
    await speak('자세를 취해주세요.');
  }

  /// 운동 완료 안내
  Future<void> speakWorkoutComplete() async {
    await speak('운동이 완료되었습니다. 수고하셨습니다!');
  }

  /// 낙상 감지 안내
  Future<void> speakFallDetection() async {
    await speak('괜찮으신가요? 문제가 없으시면 화면을 터치해주세요.');
  }

  /// 분석 중 안내
  Future<void> speakAnalyzing() async {
    await speak('분석 중입니다. 잠시만 기다려주세요.');
  }

  /// 실시간 자세 교정 피드백 (짧은 문장)
  /// [message]: 영어 또는 한국어 짧은 교정 메시지
  Future<void> speakFormCorrection(String message) async {
    if (!_initialized) await initialize();
    if (message.isEmpty) return;

    // 현재 재생 중이면 스킵 (너무 많은 피드백 방지)
    // 짧은 메시지이므로 빠른 속도로 재생
    await _flutterTts.setSpeechRate(0.6);
    await _flutterTts.speak(message);
    await _flutterTts.setSpeechRate(0.5); // 원래 속도로 복원
  }

  /// 언어 설정 변경
  Future<void> setLanguage(String languageCode) async {
    // 'en' or 'ko'
    if (languageCode == 'en') {
      await _flutterTts.setLanguage('en-US');
    } else {
      await _flutterTts.setLanguage('ko-KR');
    }
  }
}
