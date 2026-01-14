import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/exercise_config.dart';

/// RepCounter - Rep 카운팅 로직
class RepCounter {
  final ExerciseConfig config;

  // 상태
  bool _isInStartPosition = true;
  bool _wasAtTurnPoint = false;
  int _repCount = 0;

  RepCounter(this.config);

  /// 현재 Rep 카운트
  int get repCount => _repCount;

  /// 카운터 리셋
  void reset() {
    _repCount = 0;
    _isInStartPosition = true;
    _wasAtTurnPoint = false;
  }

  /// 포즈를 분석하여 Rep 카운트
  /// 반환값: 새로운 Rep이 카운트되었으면 true
  bool processFrame(Pose pose) {
    if (config.landmarks.length < 3) return false;

    // 설정된 랜드마크에서 각도 계산
    final angle = _calculateAngle(pose);
    if (angle == null) return false;

    // 상태 머신 로직
    if (_isInStartPosition) {
      // 시작 위치에서 턴 포인트로 이동 감지
      if (angle <= config.turnThreshold) {
        _wasAtTurnPoint = true;
        _isInStartPosition = false;
      }
    } else {
      // 턴 포인트에서 시작 위치로 복귀 감지
      if (angle >= config.startThreshold && _wasAtTurnPoint) {
        _repCount++;
        _isInStartPosition = true;
        _wasAtTurnPoint = false;
        return true; // 새 Rep 카운트됨
      }
    }

    return false;
  }

  /// 세 개의 랜드마크로 각도 계산
  double? _calculateAngle(Pose pose) {
    if (config.landmarks.length < 3) return null;

    final landmark1 = pose.landmarks[config.landmarks[0]];
    final landmark2 = pose.landmarks[config.landmarks[1]];
    final landmark3 = pose.landmarks[config.landmarks[2]];

    if (landmark1 == null || landmark2 == null || landmark3 == null) {
      return null;
    }

    // 벡터 계산
    final v1 = Point(landmark1.x - landmark2.x, landmark1.y - landmark2.y);
    final v2 = Point(landmark3.x - landmark2.x, landmark3.y - landmark2.y);

    // 내적과 크기로 각도 계산
    final dotProduct = v1.x * v2.x + v1.y * v2.y;
    final magnitude1 = sqrt(v1.x * v1.x + v1.y * v1.y);
    final magnitude2 = sqrt(v2.x * v2.x + v2.y * v2.y);

    if (magnitude1 == 0 || magnitude2 == 0) return null;

    final cosAngle = dotProduct / (magnitude1 * magnitude2);
    final angle = acos(cosAngle.clamp(-1.0, 1.0));

    // 라디안을 도(degree)로 변환
    return angle * 180 / pi;
  }
}

/// 2D 포인트 헬퍼
class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
}
