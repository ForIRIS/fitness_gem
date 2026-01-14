import 'dart:async';
import 'dart:io';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'gemini_service.dart';
import '../models/user_profile.dart';

/// FallDetectionService - 낙상 감지 서비스
/// 운동 중 낙상 의심 상황 감지 및 대응
class FallDetectionService {
  // 설정
  static const double _headDropThreshold = 0.3; // 화면 높이의 30% 이상 하락
  static const int _noMovementDurationMs = 5000; // 5초간 움직임 없음
  static const double _movementThreshold = 20.0; // 픽셀 단위 움직임 임계값

  // 상태
  double? _previousHeadY;
  double? _referenceHeadY;
  DateTime? _lastMovementTime;
  bool _isFallSuspected = false;
  bool _isMonitoring = false;

  // 낙상 감지 콜백
  void Function()? onFallSuspected;
  void Function(bool confirmed)? onFallConfirmed;

  // Gemini 서비스
  final GeminiService _geminiService = GeminiService();

  /// 모니터링 시작
  void startMonitoring() {
    _isMonitoring = true;
    _isFallSuspected = false;
    _previousHeadY = null;
    _referenceHeadY = null;
    _lastMovementTime = DateTime.now();
  }

  /// 모니터링 중지
  void stopMonitoring() {
    _isMonitoring = false;
    _isFallSuspected = false;
  }

  /// 포즈 업데이트 및 낙상 감지
  /// 반환: 낙상 의심 여부
  bool processPose(Pose pose, double screenHeight, String currentExercise) {
    if (!_isMonitoring || _isFallSuspected) return false;

    // 눕는 운동은 낙상 감지 제외
    if (_isLyingExercise(currentExercise)) return false;

    // 머리 위치 추출
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
    final rightEar = pose.landmarks[PoseLandmarkType.rightEar];

    double? headY;
    if (nose != null) {
      headY = nose.y;
    } else if (leftEar != null && rightEar != null) {
      headY = (leftEar.y + rightEar.y) / 2;
    } else {
      return false;
    }

    // 기준 머리 위치 설정 (첫 프레임)
    _referenceHeadY ??= headY;

    // 움직임 감지
    if (_previousHeadY != null) {
      final movement = (headY - _previousHeadY!).abs();
      if (movement > _movementThreshold) {
        _lastMovementTime = DateTime.now();
      }
    }

    // 급격한 머리 하락 감지
    final headDrop = headY - (_referenceHeadY ?? headY);
    final dropRatio = headDrop / screenHeight;

    if (dropRatio > _headDropThreshold) {
      // 머리가 급격히 하락함 + 무응답 체크
      final timeSinceLastMovement = DateTime.now().difference(
        _lastMovementTime ?? DateTime.now(),
      );

      if (timeSinceLastMovement.inMilliseconds > _noMovementDurationMs) {
        // 낙상 의심!
        _isFallSuspected = true;
        onFallSuspected?.call();
        return true;
      }
    }

    _previousHeadY = headY;
    return false;
  }

  /// 눕는 운동 여부 확인
  bool _isLyingExercise(String exercise) {
    final lower = exercise.toLowerCase();
    return lower.contains('plank') ||
        lower.contains('crunch') ||
        lower.contains('sit-up') ||
        lower.contains('dead bug') ||
        lower.contains('bridge');
  }

  /// 사용자 응답 처리 (확인 버튼 클릭)
  void userResponded() {
    _isFallSuspected = false;
    _referenceHeadY = null; // 기준 위치 리셋
    _lastMovementTime = DateTime.now();
  }

  /// 타임아웃 시 Gemini 분석 요청
  Future<bool> analyzeWithGemini({
    required File videoFile,
    required UserProfile profile,
  }) async {
    final isFall = await _geminiService.analyzeFallDetection(
      videoFile: videoFile,
      profile: profile,
    );

    onFallConfirmed?.call(isFall);
    return isFall;
  }

  /// 낙상 감지 상태 리셋
  void reset() {
    _isFallSuspected = false;
    _previousHeadY = null;
    _referenceHeadY = null;
    _lastMovementTime = DateTime.now();
  }

  /// 현재 낙상 의심 상태
  bool get isFallSuspected => _isFallSuspected;

  /// 모니터링 중인지 여부
  bool get isMonitoring => _isMonitoring;
}
